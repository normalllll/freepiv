#![allow(dead_code)]
use flutter_rust_bridge::frb;
use pixiv_rs::api::PixivApi;

#[frb(external)]
impl PixivApi{
    #[frb(sync)]
    pub fn new() {}
    #[frb(sync)]
    pub fn account() {}

    #[frb(sync)]
    pub fn set_account() {}

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