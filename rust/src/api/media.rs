use crate::frb_generated::StreamSink;
use flutter_rust_bridge::frb;
use futures_util::{Stream, StreamExt};
use std::collections::HashMap;
use tokio_util::sync::CancellationToken;

pub struct MediaChunk {
    pub bytes: Vec<u8>,
    pub received: u64,
    pub total: Option<u64>,
}

/// Stops a [stream_media] download from Dart as soon as its stream is
/// cancelled, including while the request still waits for its response.
#[frb(opaque)]
pub struct MediaCancel {
    token: CancellationToken,
}

impl MediaCancel {
    #[frb(sync)]
    pub fn new() -> Self {
        Self {
            token: CancellationToken::new(),
        }
    }

    #[frb(sync)]
    pub fn cancel(&self) {
        self.token.cancel();
    }
}

pub async fn stream_media(
    url: String,
    proxy: Option<String>,
    headers: HashMap<String, String>,
    cancel: &MediaCancel,
    sink: StreamSink<MediaChunk>,
) -> Result<(), String> {
    // The generated Dart entry point returns the sink stream immediately and
    // does not await this function's Future. Report transport errors on that
    // stream so the image loader can retry them instead of leaking an error
    // from the detached call.
    let result = match pixiv_rs::media::stream_media(url, proxy, headers) {
        Ok(stream) => {
            forward_media(stream, &cancel.token, |chunk| {
                sink.add(MediaChunk {
                    bytes: chunk.bytes,
                    received: chunk.received,
                    total: chunk.total,
                })
                .is_ok()
            })
            .await
        }
        Err(error) => Err(error),
    };
    if let Err(error) = result {
        let _ = sink.add_error(error);
    }
    Ok(())
}

/// Passes each chunk of [stream] to [add] until the stream ends, [add]
/// declines one, or [cancel] fires. Cancelling drops the stream at once,
/// which drops the request or response and closes its connection.
async fn forward_media<S>(
    stream: S,
    cancel: &CancellationToken,
    mut add: impl FnMut(pixiv_rs::media::MediaChunk) -> bool,
) -> Result<(), String>
where
    S: Stream<Item = Result<pixiv_rs::media::MediaChunk, String>> + Unpin,
{
    let mut stream = stream;
    loop {
        let next = tokio::select! {
            biased;
            _ = cancel.cancelled() => return Ok(()),
            next = stream.next() => next,
        };
        let Some(chunk) = next else {
            return Ok(());
        };
        if !add(chunk?) {
            return Ok(());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;
    use tokio::io::AsyncReadExt;

    #[tokio::test]
    async fn a_cancel_before_the_response_ends_the_download_and_closes_its_connection() {
        // A server that accepts the connection and never answers it.
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let port = listener.local_addr().unwrap().port();
        let stream = pixiv_rs::media::stream_media(
            format!("https://127.0.0.1:{port}/picture.jpg"),
            None,
            HashMap::new(),
        )
        .unwrap();
        let cancel = CancellationToken::new();
        let download = {
            let cancel = cancel.clone();
            tokio::spawn(async move { forward_media(stream, &cancel, |_| true).await })
        };
        let (mut socket, _) = listener.accept().await.unwrap();
        let mut hello = vec![0; 4096];
        assert!(socket.read(&mut hello).await.unwrap() > 0);

        cancel.cancel();
        let ended = tokio::time::timeout(Duration::from_secs(1), download).await;
        assert_eq!(ended.expect("the download ends").unwrap(), Ok(()));
        let closed = tokio::time::timeout(Duration::from_secs(1), socket.read(&mut hello)).await;
        assert!(matches!(
            closed.expect("the connection closes"),
            Ok(0) | Err(_)
        ));
    }
}
