use crate::frb_generated::StreamSink;
use flutter_rust_bridge::frb;
use futures_util::StreamExt;
use std::path::PathBuf;

#[frb]
#[derive(Clone, Debug)]
pub enum FrbDownloadBytesEvent {
    Progress { received: u64, total: u64 },
    Done { bytes: Vec<u8> },
}

#[frb]
#[derive(Clone, Debug)]
pub enum FrbDownloadFileEvent {
    Progress { received: u64, total: u64 },
    Done { path: String },
}

pub async fn download_to_memory(
    url: String,
    proxy: Option<String>,
    sink: StreamSink<FrbDownloadBytesEvent>,
) -> Result<(), String> {
    let mut stream = pixiv_rs::download_to_memory(url, proxy).map_err(|e| e.to_string())?;
    let mut completed = false;

    while let Some(event) = stream.next().await {
        let event = event.map_err(|e| e.to_string())?;

        let send_result = match event {
            pixiv_rs::DownloadEvent::Progress { received, total } => {
                sink.add(FrbDownloadBytesEvent::Progress {
                    received: received as u64,
                    total: total as u64,
                })
            }
            pixiv_rs::DownloadEvent::Done { output } => {
                completed = true;
                sink.add(FrbDownloadBytesEvent::Done { bytes: output })
            }
        };

        if let Err(error) = send_result {
            stream.cancel();
            return Err(format!("Download event sink closed: {error:?}"));
        }
    }

    if !completed {
        return Err("Download ended without completion event".to_owned());
    }

    Ok(())
}

pub async fn download_to_file(
    url: String,
    path: String,
    proxy: Option<String>,
    sink: StreamSink<FrbDownloadFileEvent>,
) -> Result<(), String> {
    let path = PathBuf::from(path);

    let mut stream = pixiv_rs::download_to_file(url, path, proxy).map_err(|e| e.to_string())?;
    let mut completed = false;

    while let Some(event) = stream.next().await {
        let event = event.map_err(|e| e.to_string())?;

        let send_result = match event {
            pixiv_rs::DownloadEvent::Progress { received, total } => {
                sink.add(FrbDownloadFileEvent::Progress {
                    received: received as u64,
                    total: total as u64,
                })
            }
            pixiv_rs::DownloadEvent::Done { output } => {
                completed = true;
                sink.add(FrbDownloadFileEvent::Done {
                    path: output.to_string_lossy().to_string(),
                })
            }
        };

        if let Err(error) = send_result {
            stream.cancel();
            return Err(format!("Download event sink closed: {error:?}"));
        }
    }

    if !completed {
        return Err("Download ended without completion event".to_owned());
    }

    Ok(())
}
