/*
 * Copyright (c) 2020, Niklas Hauser
 *
 * This file is part of the modm project.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
// ----------------------------------------------------------------------------

#include <modm/board.hpp>
#include <modm/io.hpp>
#include <modm/processing.hpp>

// ----------------------------------------------------------------------------

using namespace Board;

#if CFG_TUD_CDC
modm::IODeviceWrapper<UsbUart0, modm::IOBuffer::DiscardIfFull> usb_io_device0;
modm::IOStream usb_stream0(usb_io_device0);

// Set all four logger streams to use the CDC device
//modm::log::Logger modm::log::debug(usb_io_device0);
//modm::log::Logger modm::log::info(usb_io_device0);
//modm::log::Logger modm::log::warning(usb_io_device0);
//modm::log::Logger modm::log::error(usb_io_device0);

// Set the log level
#undef	MODM_LOG_LEVEL
#define	MODM_LOG_LEVEL modm::log::DEBUG
#endif

modm::PeriodicTimer tmr{2.5s};

// Invoked when device is mounted
void tud_mount_cb() { tmr.restart(1s); }
// Invoked when device is unmounted
void tud_umount_cb() { tmr.restart(250ms); }
// Invoked when usb bus is suspended
// remote_wakeup_en : if host allow us  to perform remote wakeup
// Within 7ms, device must draw an average of current less than 2.5 mA from bus
void tud_suspend_cb(bool) { tmr.restart(2.5s); }
// Invoked when usb bus is resumed
void tud_resume_cb() { tmr.restart(1s); }

//using MyI2cMaster	= modm::platform::I2cMaster1;
//using I2cScl 		= modm::platform::GpioB8;
//using I2cSda 		= modm::platform::GpioB9;

// ----------------------------------------------------------------------------

int
main()
{
	Board::initialize();
	//Board::initializeUsbHs();
    Board::initializeUsbFs();
	tusb_init();

	while (true)
	{
		tud_task();

#if CFG_TUD_CDC
		// Do a loopback on the CDC
		if (char input; usb_stream0.get(input), input != modm::IOStream::eof) {
			usb_stream0 << input;
		}
#endif
		if (tmr.execute())
		{
			Leds::toggle();
			static uint8_t counter{0};
#ifdef MODM_BOARD_HAS_LOGGER
			MODM_LOG_INFO << "Loop counter: " << (counter++) << modm::endl;
#endif
#if CFG_TUD_CDC
			usb_stream0 << "Hello World from USB: " << (counter++) << modm::endl;
#endif
		}
	}

	return 0;
}
