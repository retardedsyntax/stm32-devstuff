/*
 * Copyright (c) 2013, Kevin Läufer
 * Copyright (c) 2013-2014, Sascha Schade
 * Copyright (c) 2013, 2015-2017, Niklas Hauser
 *
 * This file is part of the modm project.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
// ----------------------------------------------------------------------------

#include <modm/platform.hpp>
#include <modm/debug/logger.hpp>
#include <modm/board.hpp>
#include <modm/processing.hpp>
#include <modm/architecture/interface/i2c_device.hpp>
#include <modm/processing/resumable.hpp>

using namespace Board;

// ----------------------------------------------------------------------------
// Set the log level
#undef	MODM_LOG_LEVEL
#define	MODM_LOG_LEVEL modm::log::DEBUG

//#define SERIAL_DEBUGGING 1

// Create an IODeviceWrapper around the Uart Peripheral we want to use
using Usart2 = BufferedUart<UsartHal2>;
modm::IODeviceWrapper< Usart2, modm::IOBuffer::BlockIfFull > loggerDevice;

// Set all four logger streams to use the UART
modm::log::Logger modm::log::debug(loggerDevice);
modm::log::Logger modm::log::info(loggerDevice);
modm::log::Logger modm::log::warning(loggerDevice);
modm::log::Logger modm::log::error(loggerDevice);

// ----------------------------------------------------------------------------

using MyI2cMaster = modm::platform::I2cMaster1;
using I2cScl      = modm::platform::GpioB6;
using I2cSda      = modm::platform::GpioB7;

template < class I2cMaster >
class I2cTest : public modm::I2cDevice< I2cMaster, 2 >
{
public:
	I2cTest(uint8_t address);
};

template < typename I2cMaster >
I2cTest<I2cMaster>::I2cTest(uint8_t address) : 
	modm::I2cDevice<I2cMaster, 2>(address)
{
}

//template < typename I2cMaster >
//modm::ResumableResult<bool>
//I2cTest<I2cMaster>::ping()
//{
//	return modm::I2cDevice<I2cMaster, 2>::ping();
//}

I2cTest<MyI2cMaster> i2c(0x00);

int
main()
{
	Board::initialize();

	// initialize Uart2 for MODM_LOG_
	Usart2::connect<GpioOutputA2::Tx>();
	Usart2::initialize<Board::SystemClock, 115200_Bd>();

	MyI2cMaster::connect<I2cScl::Scl, I2cSda::Sda>();
	MyI2cMaster::initialize<Board::SystemClock, 100_kHz>();

	static uint8_t buf[256]{0}; 

	while (true)
	{
		modm::delay(250ms);
		MODM_LOG_DEBUG << "Foo\r\n";
		Board::LedSouth::toggle();

		for(uint8_t ii = 1; ii < 0x80; ii++) {
			i2c.setAddress(ii);
			if (i2c.ping()) {
				MODM_LOG_DEBUG << "Device found on address 0x" << modm::hex << ii << "\r\n";
				//MODM_LOG_DEBUG << "Read 256 bytes at address 0x78 \r\n";
				Board::LedNorth::toggle();
			}
			modm::delay(10ms);
		}
	}

	//Board::LedNorth::set();

	//while (true)
	//{
	//	Board::LedNorth::toggle();
	//	modm::delay(50ms);
	//	MODM_LOG_INFO    << "\r\nLeds: " << Leds::read()  << modm::endl;
	//	Board::LedNorthEast::toggle();
	//	modm::delay(50ms);
	//	MODM_LOG_INFO    << "\r\nLeds: " << Leds::read()  << modm::endl;
	//	Board::LedEast::toggle();
	//	modm::delay(50ms);
	//	MODM_LOG_INFO    << "\r\nLeds: " << Leds::read()  << modm::endl;
	//	Board::LedSouthEast::toggle();
	//	modm::delay(50ms);
	//	MODM_LOG_INFO    << "\r\nLeds: " << Leds::read()  << modm::endl;
	//	Board::LedSouth::toggle();
	//	modm::delay(50ms);
	//	MODM_LOG_INFO    << "\r\nLeds: " << Leds::read()  << modm::endl;
	//	Board::LedSouthWest::toggle();
	//	modm::delay(50ms);
	//	MODM_LOG_INFO    << "\r\nLeds: " << Leds::read()  << modm::endl;
	//	Board::LedWest::toggle();
	//	modm::delay(50ms);
	//	MODM_LOG_INFO    << "\r\nLeds: " << Leds::read()  << modm::endl;
	//	Board::LedNorthWest::toggle();
	//	modm::delay(50ms);
	//	MODM_LOG_INFO    << "\r\nLeds: " << Leds::read()  << modm::endl;
	//}

	return 0;
}