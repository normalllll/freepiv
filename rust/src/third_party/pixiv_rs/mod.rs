#![allow(dead_code)]
use flutter_rust_bridge::frb;
use pixiv_rs::api::PixivApi;
use pixiv_rs::fanbox::FanboxApi;

#[frb(external)]
impl FanboxApi {
    #[frb(sync)]
    pub fn new() {}
}

#[frb(external)]
#[frb(non_opaque)]
pub enum FanboxFeed {}

#[frb(external)]
#[frb(non_opaque)]
pub enum FanboxBlock {}

#[frb(external)]
impl PixivApi {
    #[frb(sync)]
    pub fn new() {}
    #[frb(sync)]
    pub fn account() {}

    #[frb(sync)]
    pub fn set_account() {}

    #[frb(sync)]
    pub fn set_proxy() {}

    #[frb(sync)]
    pub fn generate_login_url() {}
}

#[frb(external)]
#[frb(dart_metadata = ("freezed"), json_serializable)]
pub struct UserAccountResult;

#[frb(external)]
#[frb(dart_metadata = ("freezed"), json_serializable)]
pub struct LocalUser;

#[frb(external)]
#[frb(dart_metadata = ("freezed"), json_serializable)]
pub struct LocalUserProfileImageUrls;
