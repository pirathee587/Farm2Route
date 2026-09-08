package com.farm2route.catalog.service;

import com.farm2route.common.exception.BusinessRuleException;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Normalizes and evaluates the package's existing weekly schedule-days array.
 * Empty schedules preserve the legacy package behavior and are available on any day.
 * Instant pickup times are evaluated in UTC because the booking model stores an Instant
 * and does not carry a separate pickup-location timezone.
 */
public final class PackageScheduleValidator {
    private PackageScheduleValidator() {
    }

    public static List<String> normalize(List<String> scheduleDays) {
        if (scheduleDays == null || scheduleDays.isEmpty()) {
            return new ArrayList<>();
        }

        Set<DayOfWeek> days = EnumSet.noneOf(DayOfWeek.class);
        for (String value : scheduleDays) {
            if (value == null || value.isBlank()) {
                throw new BusinessRuleException("Schedule days must contain valid day names");
            }
            String normalized = value.trim().toUpperCase(Locale.ROOT);
            final DayOfWeek day;
            try {
                day = DayOfWeek.valueOf(normalized);
            } catch (IllegalArgumentException ex) {
                throw new BusinessRuleException("Invalid schedule day: " + value);
            }
            if (!days.add(day)) {
                throw new BusinessRuleException("Duplicate schedule day: " + normalized);
            }
        }

        return days.stream().map(Enum::name).toList();
    }

    public static boolean isAvailableOn(List<String> scheduleDays, Instant pickupAt) {
        if (scheduleDays == null || scheduleDays.isEmpty()) {
            return true;
        }
        if (pickupAt == null) {
            throw new BusinessRuleException("Scheduled pickup time is required for a recurring package");
        }
        DayOfWeek pickupDay = pickupAt.atZone(ZoneOffset.UTC).getDayOfWeek();
        return normalize(scheduleDays).contains(pickupDay.name());
    }
}
