// test Jewish holiday
/datum/unit_test/hanukkah_2123/Run()
	var/datum/holiday/hebrew/hanukkah/hanukkah = new
	TEST_ASSERT(hanukkah.shouldCelebrate(14, DECEMBER, 2123, TUESDAY), "December 14, 2123 was not Hanukkah.")

// test Islamic holiday
/datum/unit_test/ramadan_2165/Run()
	var/datum/holiday/islamic/ramadan/ramadan = new
	TEST_ASSERT(ramadan.shouldCelebrate(6, NOVEMBER, 2165, WEDNESDAY), "November 6, 2165 was not Ramadan.")

// nth day of week
/datum/unit_test/thanksgiving_2020/Run()
	var/datum/holiday/nth_week/thanksgiving/thanksgiving = new
	TEST_ASSERT(thanksgiving.shouldCelebrate(26, NOVEMBER, 2020, THURSDAY), "November 26, 2020 was not Thanksgiving.")

// another nth day of week
/datum/unit_test/mother_3683/Run()
	var/datum/holiday/nth_week/mother/mother = new
	TEST_ASSERT(mother.shouldCelebrate(9, MAY, 3683, 2, SUNDAY), "May 9, 3683 was not Mother's Day.")

// plain old simple holiday
/datum/unit_test/hello_2020/Run()
	var/datum/holiday/hello/hello = new
	TEST_ASSERT(hello.shouldCelebrate(21, NOVEMBER, 2020, SATURDAY), "November 21, 2020 was not Hello day.")

// holiday which goes across months
/datum/unit_test/new_year_1983/Run()
	var/datum/holiday/new_year/new_year = new
	TEST_ASSERT(new_year.shouldCelebrate(2, JANUARY, 1983, SUNDAY), "January 2, 1983 was not New Year.")
