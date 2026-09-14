use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FanboxBrowserFailure {
    RuntimeMissing,
    Unavailable,
    Busy,
    ProxyUnsupported,
    CleanupFailed,
    TimedOut,
}

impl std::fmt::Display for FanboxBrowserFailure {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}
impl std::error::Error for FanboxBrowserFailure {}

/// Owns cancellation independently of the native window's UI thread.
#[flutter_rust_bridge::frb(opaque)]
pub struct FanboxBrowserLogin {
    pub(crate) cancelled: Arc<AtomicBool>,
}

impl FanboxBrowserLogin {
    #[flutter_rust_bridge::frb(sync)]
    pub fn new() -> Self {
        Self {
            cancelled: Arc::new(AtomicBool::new(false)),
        }
    }

    #[flutter_rust_bridge::frb(sync)]
    pub fn cancel(&self) {
        self.cancelled.store(true, Ordering::Release);
    }

    pub async fn run(
        &self,
        support_directory: String,
        proxy: Option<String>,
        language: String,
        title: String,
        check_label: String,
        cancel_label: String,
        failed_label: String,
    ) -> Result<Option<String>, FanboxBrowserFailure> {
        #[cfg(target_os = "windows")]
        return crate::fanbox_browser::open(
            support_directory,
            proxy,
            language,
            title,
            check_label,
            cancel_label,
            failed_label,
            self.cancelled.clone(),
            false,
        )
        .await;
        #[cfg(not(target_os = "windows"))]
        {
            let _ = (
                support_directory,
                proxy,
                language,
                title,
                check_label,
                cancel_label,
                failed_label,
            );
            Err(FanboxBrowserFailure::Unavailable)
        }
    }
}

pub fn fanbox_browser_available() -> bool {
    #[cfg(target_os = "windows")]
    return wry::webview_version().is_ok();
    #[cfg(not(target_os = "windows"))]
    false
}

pub async fn clear_fanbox_browser(support_directory: String) -> Result<(), FanboxBrowserFailure> {
    #[cfg(target_os = "windows")]
    {
        // Persist the reset request first. A failed cleanup must not restore the
        // old account when WebView2 is repaired or installed later.
        let root = std::path::Path::new(&support_directory);
        if !root.join("fanbox-browser").exists() {
            return Ok(());
        }
        std::fs::create_dir_all(root).map_err(|_| FanboxBrowserFailure::CleanupFailed)?;
        std::fs::write(root.join("fanbox-browser-reset"), b"")
            .map_err(|_| FanboxBrowserFailure::CleanupFailed)?;
        crate::fanbox_browser::open(
            support_directory,
            None,
            String::new(),
            String::new(),
            String::new(),
            String::new(),
            String::new(),
            Arc::new(AtomicBool::new(false)),
            true,
        )
        .await
        .map_err(|_| FanboxBrowserFailure::CleanupFailed)?;
        Ok(())
    }
    #[cfg(not(target_os = "windows"))]
    {
        let _ = support_directory;
        Ok(())
    }
}
