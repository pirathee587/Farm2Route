package com.farm2route.catalog.service;

import com.farm2route.common.exception.BusinessRuleException;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PackageScheduleValidatorTest {
    @Test
    void normalizesDayNamesAndUsesMondayFirstOrdering() {
        assertThat(PackageScheduleValidator.normalize(List.of(" friday ", "MONDAY", "wednesday")))
                .containsExactly("MONDAY", "WEDNESDAY", "FRIDAY");
    }

    @Test
    void rejectsInvalidDayNames() {
        assertThatThrownBy(() -> PackageScheduleValidator.normalize(List.of("FUNDAY")))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Invalid schedule day");
    }

    @Test
    void rejectsDuplicateDays() {
        assertThatThrownBy(() -> PackageScheduleValidator.normalize(List.of("MONDAY", "monday")))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Duplicate schedule day");
    }

    @Test
    void emptyScheduleRemainsAvailableOnAnyDay() {
        assertThat(PackageScheduleValidator.normalize(List.of())).isEmpty();
        assertThat(PackageScheduleValidator.isAvailableOn(List.of(), Instant.parse("2026-09-08T10:00:00Z")))
                .isTrue();
    }

    @Test
    void matchesRequestedPickupDayInUtc() {
        List<String> schedule = List.of("MONDAY", "WEDNESDAY");
        assertThat(PackageScheduleValidator.isAvailableOn(schedule,
                Instant.parse("2026-09-07T10:00:00Z"))).isTrue();
        assertThat(PackageScheduleValidator.isAvailableOn(schedule,
                Instant.parse("2026-09-08T10:00:00Z"))).isFalse();
    }
}
