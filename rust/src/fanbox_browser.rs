//! The browser and all COM objects stay on one dedicated Windows UI thread.
use crate::api::fanbox_login::FanboxBrowserFailure as Failure;
use muda::{Menu, MenuEvent, MenuItem};
use std::{
    path::PathBuf,
    sync::{
        atomic::{AtomicBool, Ordering},
        mpsc, Arc, OnceLock,
    },
    time::{Duration, Instant},
};
use tao::{
    event::{Event, WindowEvent},
    event_loop::{ControlFlow, EventLoopBuilder},
    platform::{
        run_return::EventLoopExtRunReturn,
        windows::{EventLoopBuilderExtWindows, WindowExtWindows},
    },
    window::WindowBuilder,
};
use wry::{NewWindowResponse, ProxyConfig, ProxyEndpoint, WebContext, WebViewBuilder};

#[path = "fanbox_browser_cookies.rs"]
mod cookies;

static BUSY: AtomicBool = AtomicBool::new(false);
static THREAD: OnceLock<Option<mpsc::Sender<Job>>> = OnceLock::new();

struct Job {
    root: PathBuf,
    proxy: Option<String>,
    language: String,
    title: String,
    check_label: String,
    cancel_label: String,
    failed_label: String,
    cancelled: Arc<AtomicBool>,
    clear: bool,
    runtime: tokio::runtime::Handle,
    reply: tokio::sync::oneshot::Sender<Result<Option<String>, Failure>>,
}

struct BusyLease;
impl Drop for BusyLease {
    fn drop(&mut self) {
        BUSY.store(false, Ordering::Release);
    }
}

#[allow(clippy::too_many_arguments)]
pub(crate) async fn open(
    root: String,
    proxy: Option<String>,
    language: String,
    title: String,
    check_label: String,
    cancel_label: String,
    failed_label: String,
    cancelled: Arc<AtomicBool>,
    clear: bool,
) -> Result<Option<String>, Failure> {
    if BUSY
        .compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire)
        .is_err()
    {
        return Err(Failure::Busy);
    }
    let lease = BusyLease;
    if wry::webview_version().is_err() {
        return Err(Failure::RuntimeMissing);
    }
    let sender = THREAD
        .get_or_init(|| {
            let (tx, rx) = mpsc::channel::<Job>();
            std::thread::Builder::new()
                .name("freepiv-fanbox-login".into())
                .spawn(move || {
                    let mut events = EventLoopBuilder::new()
                        .with_any_thread(true)
                        .with_dpi_aware(false)
                        .build();
                    for job in rx {
                        // Release the process-wide lease even if a caller drops its future.
                        let lease = BusyLease;
                        let result = run(&mut events, &job);
                        drop(lease);
                        let _ = job.reply.send(result);
                    }
                })
                .ok()
                .map(|_| tx)
        })
        .as_ref()
        .ok_or(Failure::Unavailable)?;
    let (reply, result) = tokio::sync::oneshot::channel();
    sender
        .send(Job {
            root: root.into(),
            proxy,
            language,
            title,
            check_label,
            cancel_label,
            failed_label,
            cancelled,
            clear,
            runtime: tokio::runtime::Handle::current(),
            reply,
        })
        .map_err(|_| Failure::Unavailable)?;
    std::mem::forget(lease); // Ownership transferred to the window thread.
    result.await.map_err(|_| Failure::Unavailable)?
}

fn proxy_config(value: Option<&str>) -> Result<Option<ProxyConfig>, Failure> {
    let Some(value) = value else {
        return Ok(None);
    };
    let uri = reqwest::Url::parse(value).map_err(|_| Failure::ProxyUnsupported)?;
    if !uri.username().is_empty() || uri.password().is_some() {
        return Err(Failure::ProxyUnsupported);
    }
    let endpoint = ProxyEndpoint {
        host: uri.host_str().ok_or(Failure::ProxyUnsupported)?.into(),
        port: uri
            .port_or_known_default()
            .or_else(|| matches!(uri.scheme(), "socks5" | "socks5h").then_some(1080))
            .ok_or(Failure::ProxyUnsupported)?
            .to_string(),
    };
    Ok(Some(match uri.scheme() {
        "http" => ProxyConfig::Http(endpoint),
        "socks5" | "socks5h" => ProxyConfig::Socks5(endpoint),
        _ => return Err(Failure::ProxyUnsupported),
    }))
}

fn allowed_navigation(value: &str) -> bool {
    // Authentication can cross providers; only the fixed FANBOX origin is ever
    // used for cookie capture. External protocols and downloads are not launched.
    reqwest::Url::parse(value).is_ok_and(|url| {
        url.scheme() == "https" && url.username().is_empty() && url.password().is_none()
    })
}

fn run(events: &mut tao::event_loop::EventLoop<()>, job: &Job) -> Result<Option<String>, Failure> {
    if job.cancelled.load(Ordering::Acquire) {
        return Ok(None);
    }
    let proxy = proxy_config(job.proxy.as_deref())?;
    std::fs::create_dir_all(&job.root).map_err(|_| Failure::Unavailable)?;
    let profile = job.root.join("fanbox-browser");
    // Never operate on a redirected profile supplied through a filesystem link.
    if std::fs::symlink_metadata(&profile).is_ok_and(|meta| meta.file_type().is_symlink()) {
        return Err(Failure::Unavailable);
    }
    let reset = job.root.join("fanbox-browser-reset");
    let mut context = WebContext::new(Some(profile));
    let window = WindowBuilder::new()
        .with_title(&job.title)
        .with_visible(false)
        .with_inner_size(tao::dpi::LogicalSize::new(960.0, 760.0))
        .build(events)
        .map_err(|_| Failure::Unavailable)?;
    let (popup_tx, popup_rx) = mpsc::channel();
    let mut builder = WebViewBuilder::new_with_web_context(&mut context)
        .with_devtools(false)
        .with_navigation_handler(|url| allowed_navigation(&url))
        .with_new_window_req_handler(move |url, _| {
            if allowed_navigation(&url) {
                let _ = popup_tx.send(url);
            }
            NewWindowResponse::Deny
        })
        .with_download_started_handler(|_, _| false);
    if let Some(proxy) = proxy {
        builder = builder.with_proxy_config(proxy);
    }
    let view = builder.build(&window).map_err(|_| Failure::Unavailable)?;
    if reset.exists() || job.clear {
        cookies::clear(&view)?;
        if reset.exists() {
            std::fs::remove_file(&reset).map_err(|_| Failure::CleanupFailed)?;
        }
    }
    if job.clear {
        return Ok(None);
    }
    let check = MenuItem::new(&job.check_label, true, None);
    let cancel = MenuItem::new(&job.cancel_label, true, None);
    let menu = Menu::with_items(&[&check, &cancel]).map_err(|_| Failure::Unavailable)?;
    // SAFETY: the menu and HWND live on this owning UI thread.
    unsafe { menu.init_for_hwnd(window.hwnd()) }.map_err(|_| Failure::Unavailable)?;
    view.load_url("https://www.fanbox.cc/")
        .map_err(|_| Failure::Unavailable)?;
    window.set_visible(true);
    let deadline = Instant::now() + Duration::from_secs(15 * 60);
    let mut next_capture = Instant::now();
    let mut capture = None;
    let mut capture_deadline = Instant::now();
    let mut verification: Option<tokio::task::JoinHandle<()>> = None;
    let (verified_tx, verified_rx) = mpsc::channel();
    let mut last_candidate = String::new();
    let mut result = Ok(None);
    events.run_return(|event, _, flow| {
        *flow = ControlFlow::WaitUntil(Instant::now() + Duration::from_millis(100));
        let mut closing = job.cancelled.load(Ordering::Acquire)
            || matches!(
                event,
                Event::WindowEvent {
                    event: WindowEvent::CloseRequested,
                    ..
                }
            );
        while let Ok(event) = MenuEvent::receiver().try_recv() {
            if event.id == *cancel.id() {
                closing = true;
            }
            if event.id == *check.id() {
                last_candidate.clear();
                next_capture = Instant::now();
            }
        }
        if Instant::now() >= deadline {
            result = Err(Failure::TimedOut);
            closing = true;
        }
        if closing {
            *flow = ControlFlow::Exit;
            return;
        }
        while let Ok(url) = popup_rx.try_recv() {
            let _ = view.load_url(&url);
        }
        if let Ok(verified) = verified_rx.try_recv() {
            verification = None;
            match verified {
                Some(session) => {
                    result = Ok(Some(session));
                    *flow = ControlFlow::Exit;
                    return;
                }
                None => window.set_title(&format!("{} — {}", job.title, job.failed_label)),
            }
        }
        if capture.is_none() && verification.is_none() && Instant::now() >= next_capture {
            match cookies::read(&view) {
                Ok(receiver) => {
                    capture = Some(receiver);
                    capture_deadline = Instant::now() + Duration::from_secs(10);
                }
                Err(_) => window.set_title(&format!("{} — {}", job.title, job.failed_label)),
            }
            next_capture = Instant::now() + Duration::from_secs(2);
        }
        let candidate = capture.as_ref().and_then(|rx| rx.try_recv().ok());
        if candidate.is_some() || Instant::now() >= capture_deadline {
            capture = None;
        }
        if let Some(Ok(Some(session))) = candidate {
            if session != last_candidate {
                last_candidate = session.clone();
                let tx = verified_tx.clone();
                let proxy = job.proxy.clone();
                let language = job.language.clone();
                verification = Some(job.runtime.spawn(async move {
                    let valid = match pixiv_rs::fanbox::FanboxApi::new(
                        session.clone(),
                        proxy,
                        language,
                        false,
                    ) {
                        Ok(api) => api.validate_session().await.is_ok(),
                        Err(_) => false,
                    };
                    let _ = tx.send(valid.then_some(session));
                }));
            }
        }
    });
    if let Some(task) = verification {
        task.abort();
    }
    window.set_visible(false);
    result
}
