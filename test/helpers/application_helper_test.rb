require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "a list date is as short as possible" do
    travel_to Time.zone.local(2026, 10, 30, 9, 0) do
      assert_equal "8h05", list_time(Time.zone.local(2026, 10, 30, 8, 5))[/>(.*)</, 1]
      assert_equal "hier", list_time(Time.zone.local(2026, 10, 29, 23, 0))[/>(.*)</, 1]
      assert_equal "27 oct.", list_time(Time.zone.local(2026, 10, 27, 15, 13))[/>(.*)</, 1]
      assert_equal "03/12/2025", list_time(Time.zone.local(2025, 12, 3, 10, 0))[/>(.*)</, 1]
      assert_nil list_time(nil)
    end
  end

  test "a date says how long ago it was" do
    now = Time.zone.local(2026, 10, 31, 23, 45)
    assert_equal "à l'instant", time_ago(now - 20.seconds, now: now)
    assert_equal "il y a 1 minute", time_ago(now - 1.minute, now: now)
    assert_equal "il y a 12 minutes", time_ago(now - 12.minutes, now: now)
    assert_equal "il y a 3 heures", time_ago(now - 3.hours, now: now)
    assert_equal "hier", time_ago(Time.zone.local(2026, 10, 30, 8, 0), now: now)
    assert_equal "il y a 15 jours", time_ago(Time.zone.local(2026, 10, 16, 14, 38), now: now)
    assert_equal "il y a 2 jours", time_ago(Time.zone.local(2026, 10, 29, 23, 50), now: now)
    assert_equal "il y a 1 mois", time_ago(Time.zone.local(2026, 9, 30, 10, 0), now: now)
    assert_equal "il y a 11 mois", time_ago(Time.zone.local(2025, 11, 30, 10, 0), now: now)
    assert_equal "il y a 1 an", time_ago(Time.zone.local(2025, 10, 31, 10, 0), now: now)
    assert_equal "il y a 3 ans", time_ago(Time.zone.local(2023, 6, 1), now: now)
  end

  test "dates show how long ago they were on hover" do
    travel_to Time.zone.local(2026, 10, 31, 23, 45) do
      sent = Time.zone.local(2026, 10, 16, 14, 38)
      assert_includes dated(sent), 'title="il y a 15 jours"'
      assert_includes dated(sent), "vendredi 16 octobre 2026"
      assert_includes list_time(sent), 'title="il y a 15 jours · vendredi 16 octobre 2026 14h38"'
      assert_nil dated(nil)
    end
  end
end
