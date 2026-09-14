use crate::api::fanbox_login::FanboxBrowserFailure as Failure;
use std::sync::mpsc;
use webview2_com::{
    take_pwstr, ClearBrowsingDataCompletedHandler, GetCookiesCompletedHandler,
    Microsoft::Web::WebView2::Win32::{ICoreWebView2Profile2, ICoreWebView2_13, ICoreWebView2_2},
};
use windows::core::{Interface, HSTRING, PWSTR};
use wry::{WebView, WebViewExtWindows};

pub(super) fn read(
    view: &WebView,
) -> Result<mpsc::Receiver<Result<Option<String>, Failure>>, Failure> {
    let (tx, rx) = mpsc::channel();
    // SAFETY: native objects and callbacks belong to the WebView's UI thread.
    // Only owned strings cross the channel; no cookie values are logged.
    unsafe {
        let webview: ICoreWebView2_2 = view
            .controller()
            .CoreWebView2()
            .and_then(|view| view.cast())
            .map_err(|_| Failure::Unavailable)?;
        webview
            .CookieManager()
            .map_err(|_| Failure::Unavailable)?
            .GetCookies(
                &HSTRING::from("https://www.fanbox.cc/"),
                &GetCookiesCompletedHandler::create(Box::new(move |status, list| {
                    let value = (|| {
                        status?;
                        let Some(list) = list else {
                            return Ok(None);
                        };
                        let mut count = 0;
                        list.Count(&mut count)?;
                        for index in 0..count.min(1024) {
                            let cookie = list.GetValueAtIndex(index)?;
                            let mut name = PWSTR::null();
                            cookie.Name(&mut name)?;
                            if take_pwstr(name) != "FANBOXSESSID" {
                                continue;
                            }
                            let mut value = PWSTR::null();
                            cookie.Value(&mut value)?;
                            let value = take_pwstr(value);
                            if !value.is_empty() && value.len() <= 8192 {
                                return Ok(Some(value));
                            }
                        }
                        Ok(None)
                    })();
                    let _ = tx.send(value.map_err(|_: windows::core::Error| Failure::Unavailable));
                    Ok(())
                })),
            )
            .map_err(|_| Failure::Unavailable)?;
    }
    Ok(rx)
}

pub(super) fn clear(view: &WebView) -> Result<(), Failure> {
    let (tx, rx) = mpsc::channel();
    // SAFETY: this profile is owned exclusively by freepiv's FANBOX login.
    unsafe {
        let webview: ICoreWebView2_13 = view
            .controller()
            .CoreWebView2()
            .and_then(|view| view.cast())
            .map_err(|_| Failure::CleanupFailed)?;
        let profile: ICoreWebView2Profile2 = webview
            .Profile()
            .and_then(|p| p.cast())
            .map_err(|_| Failure::CleanupFailed)?;
        profile
            .ClearBrowsingDataAll(&ClearBrowsingDataCompletedHandler::create(Box::new(
                move |result| {
                    let _ = tx.send(result.map_err(|_| Failure::CleanupFailed));
                    Ok(())
                },
            )))
            .map_err(|_| Failure::CleanupFailed)?;
    }
    let deadline = std::time::Instant::now() + std::time::Duration::from_secs(10);
    loop {
        match rx.try_recv() {
            Ok(result) => return result,
            Err(mpsc::TryRecvError::Disconnected) => return Err(Failure::CleanupFailed),
            Err(mpsc::TryRecvError::Empty) => {}
        }
        if std::time::Instant::now() >= deadline {
            return Err(Failure::CleanupFailed);
        }
        // Pump the STA until the asynchronous native cleanup completes.
        unsafe {
            use windows::Win32::UI::WindowsAndMessaging::*;
            let mut message = MSG::default();
            while PeekMessageW(&mut message, None, 0, 0, PM_REMOVE).as_bool() {
                let _ = TranslateMessage(&message);
                DispatchMessageW(&message);
            }
        }
        std::thread::sleep(std::time::Duration::from_millis(5));
    }
}
