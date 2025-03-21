/*
 * Copyright (c) 2021, Odin Holmes
 * Copyright (c) 2021, Raphael Lehmann
 *
 * This file is part of the modm project.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
// ----------------------------------------------------------------------------

#ifndef MODM_DS3232_HPP
#	error  "Don't include this file directly, use 'ds3232.hpp' instead!"
#endif

// ----------------------------------------------------------------------------
template < typename I2cMaster >
modm::Ds3232<I2cMaster>::Ds3232(uint8_t address)
:	I2cDevice<I2cMaster, 2>(address), dateTime{}
{
}

template < typename I2cMaster >
modm::ResumableResult<std::optional<modm::ds3232::DateTime>>
modm::Ds3232<I2cMaster>::getDateTime()
{
	RF_BEGIN();
	this->transaction.configureWriteRead(&addr_seconds, 1, scratch, 7);
	if (RF_CALL(this->runTransaction())) {
		dateTime.seconds = decodeBcd(scratch[0] & 0b0111'1111);
		dateTime.minutes = decodeBcd(scratch[1]);
		dateTime.hours = decodeBcd(scratch[2] & 0b0011'1111);
		//no need for day of the week
		dateTime.days = decodeBcd(scratch[4]);
		dateTime.months = decodeBcd(scratch[5] & 0b0001'1111);
		dateTime.years = decodeBcd(scratch[6]);
		RF_RETURN(dateTime);
	}
	RF_END_RETURN(std::nullopt);
}

template < typename I2cMaster >
modm::ResumableResult<bool>
modm::Ds3232<I2cMaster>::setDateTime(DateTime dt)
{
	RF_BEGIN();
	scratch[0] = addr_seconds;
	scratch[1] = 0b1000'0000; // stop oscillator
	this->transaction.configureWrite(scratch, 2);
	if (not RF_CALL(this->runTransaction())) {
		RF_RETURN(false);
	}
	scratch[0] = addr_seconds;
	scratch[1] = encodeBcd(dt.seconds);
	scratch[2] = encodeBcd(dt.minutes);
	scratch[3] = encodeBcd(dt.hours);
	scratch[4] = 0x00; /* no need for DoW */;
	scratch[5] = encodeBcd(dt.days);
	scratch[6] = encodeBcd(dt.months);
	scratch[7] = encodeBcd(dt.years);
	this->transaction.configureWrite(scratch, 8);
	if (not RF_CALL(this->runTransaction())) {
		RF_RETURN(false);
	}
	scratch[0] = addr_seconds;
	scratch[1] = 0b0000'0000; // start oscillator
	this->transaction.configureWrite(scratch, 2);
	RF_END_RETURN_CALL(this->runTransaction());
}

template < typename I2cMaster >
modm::ResumableResult<bool>
modm::Ds3232<I2cMaster>::oscillatorRunning()
{
	RF_BEGIN();
	this->transaction.configureWriteRead(&addr_status, 1, scratch, 1);
	if (RF_CALL(this->runTransaction())) {
		RF_RETURN((scratch[0] | 0b1000'0000 /* OSF bit */) > 0);
	}
	RF_END_RETURN(false);
}
