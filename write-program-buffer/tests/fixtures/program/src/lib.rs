#![no_std]

#[cfg(feature = "medium")]
#[no_mangle]
pub static PAD: [u8; 20_000] = [1; 20_000];

#[cfg(feature = "big")]
#[no_mangle]
pub static PAD: [u8; 4096] = [1; 4096];

#[cfg(feature = "huge")]
#[no_mangle]
pub static PAD: [u8; 10_481_816] = [1; 10_481_816];

#[no_mangle]
pub extern "C" fn entrypoint(_input: *mut u8) -> u64 {
    #[cfg(any(feature = "medium", feature = "big", feature = "huge"))]
    core::hint::black_box(&PAD);
    0
}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}
