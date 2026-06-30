#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
use std::process::Command;

pub fn get_system_proxy() -> Result<Option<String>, String> {
    get_platform_system_proxy()
}

#[cfg(target_os = "windows")]
fn get_platform_system_proxy() -> Result<Option<String>, String> {
    let enabled = query_windows_internet_setting("ProxyEnable")?;
    if !windows_proxy_enabled(&enabled) {
        return Ok(None);
    }

    let proxy_server = query_windows_internet_setting("ProxyServer")?;
    Ok(proxy_url_from_windows_proxy_server(&proxy_server))
}

#[cfg(target_os = "macos")]
fn get_platform_system_proxy() -> Result<Option<String>, String> {
    let output = command_output(Command::new("scutil").arg("--proxy"))?;
    Ok(proxy_url_from_scutil_proxy(&output))
}

#[cfg(target_os = "linux")]
fn get_platform_system_proxy() -> Result<Option<String>, String> {
    if let Some(proxy) = proxy_url_from_environment() {
        return Ok(Some(proxy));
    }

    proxy_url_from_gsettings()
}

#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
fn get_platform_system_proxy() -> Result<Option<String>, String> {
    Ok(None)
}

#[cfg(target_os = "windows")]
fn query_windows_internet_setting(name: &str) -> Result<String, String> {
    let output = command_output(
        Command::new("reg")
            .arg("query")
            .arg(r"HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings")
            .arg("/v")
            .arg(name),
    )?;

    for line in output.lines() {
        if line.contains(name) {
            if let Some((_, value)) = line.rsplit_once("    ") {
                return Ok(value.trim().to_string());
            }

            if let Some(value) = line.split_whitespace().last() {
                return Ok(value.trim().to_string());
            }
        }
    }

    Ok(String::new())
}

#[cfg(target_os = "windows")]
fn windows_proxy_enabled(value: &str) -> bool {
    let normalized = value.trim().to_ascii_lowercase();
    normalized == "1" || normalized == "0x1"
}

#[cfg(target_os = "windows")]
fn proxy_url_from_windows_proxy_server(value: &str) -> Option<String> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return None;
    }

    if !trimmed.contains('=') {
        return normalize_http_proxy_url(trimmed);
    }

    let mut https_proxy = None;

    for entry in trimmed.split(';') {
        let Some((key, proxy)) = entry.split_once('=') else {
            continue;
        };

        let key = key.trim().to_ascii_lowercase();
        let normalized_proxy = normalize_http_proxy_url(proxy.trim());

        if key == "http" && normalized_proxy.is_some() {
            return normalized_proxy;
        }

        if key == "https" && https_proxy.is_none() {
            https_proxy = normalized_proxy;
        }
    }

    https_proxy
}

#[cfg(target_os = "macos")]
fn proxy_url_from_scutil_proxy(output: &str) -> Option<String> {
    let http_enabled = scutil_value(output, "HTTPEnable").is_some_and(|value| value == "1");
    let https_enabled = scutil_value(output, "HTTPSEnable").is_some_and(|value| value == "1");

    if http_enabled {
        if let Some(proxy) = proxy_url_from_host_port(
            scutil_value(output, "HTTPProxy")?,
            scutil_value(output, "HTTPPort")?,
        ) {
            return Some(proxy);
        }
    }

    if https_enabled {
        return proxy_url_from_host_port(
            scutil_value(output, "HTTPSProxy")?,
            scutil_value(output, "HTTPSPort")?,
        );
    }

    None
}

#[cfg(target_os = "macos")]
fn scutil_value<'a>(output: &'a str, key: &str) -> Option<&'a str> {
    output.lines().find_map(|line| {
        let (line_key, value) = line.split_once(':')?;
        if line_key.trim() == key {
            Some(value.trim())
        } else {
            None
        }
    })
}

#[cfg(target_os = "linux")]
fn proxy_url_from_environment() -> Option<String> {
    for key in [
        "http_proxy",
        "HTTP_PROXY",
        "https_proxy",
        "HTTPS_PROXY",
        "all_proxy",
        "ALL_PROXY",
    ] {
        if let Ok(value) = std::env::var(key) {
            if let Some(proxy) = normalize_http_proxy_url(&value) {
                return Some(proxy);
            }
        }
    }

    None
}

#[cfg(target_os = "linux")]
fn proxy_url_from_gsettings() -> Result<Option<String>, String> {
    let mode = match command_output(
        Command::new("gsettings")
            .arg("get")
            .arg("org.gnome.system.proxy")
            .arg("mode"),
    ) {
        Ok(mode) => mode,
        Err(_) => return Ok(None),
    };

    if unquote_gsettings_value(&mode) != "manual" {
        return Ok(None);
    }

    if let Some(proxy) = gsettings_proxy_url("http")? {
        return Ok(Some(proxy));
    }

    gsettings_proxy_url("https")
}

#[cfg(target_os = "linux")]
fn gsettings_proxy_url(schema_suffix: &str) -> Result<Option<String>, String> {
    let schema = format!("org.gnome.system.proxy.{schema_suffix}");

    let host = unquote_gsettings_value(&command_output(
        Command::new("gsettings")
            .arg("get")
            .arg(&schema)
            .arg("host"),
    )?);

    let port = command_output(
        Command::new("gsettings")
            .arg("get")
            .arg(&schema)
            .arg("port"),
    )?;

    Ok(proxy_url_from_host_port(host.trim(), port.trim()))
}

#[cfg(target_os = "linux")]
fn unquote_gsettings_value(value: &str) -> String {
    value
        .trim()
        .trim_matches('\'')
        .trim_matches('"')
        .to_string()
}

#[cfg(any(target_os = "macos", target_os = "linux"))]
fn proxy_url_from_host_port(host: &str, port: &str) -> Option<String> {
    let host = host.trim();
    let port = port.trim();

    if host.is_empty() || port.is_empty() {
        return None;
    }

    normalize_http_proxy_url(&format!("{host}:{port}"))
}

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
fn normalize_http_proxy_url(value: &str) -> Option<String> {
    let trimmed = value.trim().trim_end_matches('/');

    if trimmed.is_empty() {
        return None;
    }

    let lower = trimmed.to_ascii_lowercase();

    if lower.starts_with("socks://")
        || lower.starts_with("socks4://")
        || lower.starts_with("socks5://")
    {
        return None;
    }

    if lower.starts_with("http://") || lower.starts_with("https://") {
        return Some(trimmed.to_string());
    }

    Some(format!("http://{trimmed}"))
}

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
fn command_output(command: &mut Command) -> Result<String, String> {
    let output = command.output().map_err(|error| error.to_string())?;

    if !output.status.success() {
        return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}