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
#define MODM_DS3232_HPP

#include <array>
#include <optional>

#include <modm/architecture/interface/register.hpp>
#include <modm/architecture/interface/i2c_device.hpp>
#include <modm/processing/resumable.hpp>

namespace modm
{

/// @ingroup modm_driver_ds3232
struct ds3232
{
	/// days, months, etc. are decoded (BCD) in this struct
	struct modm_packed
	DateTime
	{
		uint8_t days;
		uint8_t months;
		uint8_t years;
		uint8_t seconds;
		uint8_t minutes;
		uint8_t hours;
	};
};

/**
 * @ingroup modm_driver_ds3232
 * @author	Odin Holmes
 * @author	Raphael Lehmann
 */
template < class I2cMaster >
class Ds3232 :	public ds3232,
					public modm::I2cDevice<I2cMaster, 2>
{
public:
	Ds3232(uint8_t address = 0x68);

	modm::ResumableResult<std::optional<modm::ds3232::DateTime>>
	getDateTime();

	modm::ResumableResult<bool>
	setDateTime(DateTime);

	modm::ResumableResult<bool>
	oscillatorRunning();

private:
	constexpr uint8_t
	decodeBcd(uint8_t bcd)
	{
		return (bcd / 16 * 10) + (bcd % 16);
	}

	constexpr uint8_t
	encodeBcd(uint8_t decimal)
	{
		return (decimal / 10 * 16) + (decimal % 10);
	}

private:
	DateTime dateTime;

	//address definition for registers of the DS3232
	const uint8_t addr_seconds = 0x00;
	const uint8_t addr_minutes = 0x01;
	const uint8_t addr_hours = 0x02;
	const uint8_t addr_weekday = 0x03; //not using day of the week
	const uint8_t addr_days = 0x04;
	const uint8_t addr_months = 0x05;
	const uint8_t addr_years = 0x06;

	const uint8_t addr_control = 0x0e;
	const uint8_t addr_status = 0x0f;

	uint8_t scratch[8];
};

} // namespace modm

#include "ds3232_impl.hpp"

#endif // MODM_DS3232_HPP
