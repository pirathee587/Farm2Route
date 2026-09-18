package com.farm2route.admin.repository;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleType;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest
@ActiveProfiles("test")
class AdminKycRepositoryTest {

    @Autowired
    private AgencyProfileRepository agencyProfileRepository;

    @Autowired
    private DriverProfileRepository driverProfileRepository;

    @Autowired
    private VehicleRepository vehicleRepository;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        cleanUp();
    }

    @AfterEach
    void tearDown() {
        cleanUp();
    }

    private void cleanUp() {
        vehicleRepository.deleteAll();
        driverProfileRepository.deleteAll();
        agencyProfileRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("AgencyProfileRepository.findByKycStatusIn filters agencies accurately")
    void testAgencyFindByKycStatusIn() {
        User user1 = userRepository.save(User.builder().email("agency1@test.com").phoneNumber("+94771111111").passwordHash("pass").role(Role.AGENCY).status(UserStatus.ACTIVE).build());
        User user2 = userRepository.save(User.builder().email("agency2@test.com").phoneNumber("+94772222222").passwordHash("pass").role(Role.AGENCY).status(UserStatus.ACTIVE).build());
        User user3 = userRepository.save(User.builder().email("agency3@test.com").phoneNumber("+94773333333").passwordHash("pass").role(Role.AGENCY).status(UserStatus.ACTIVE).build());

        agencyProfileRepository.save(AgencyProfile.builder().user(user1).companyName("Agency One").businessRegistrationNumber("BR-001").officeAddress("Colombo").district("Colombo").contactPersonName("John").contactPersonPhone("+94771111111").kycStatus(KycStatus.PENDING).build());
        agencyProfileRepository.save(AgencyProfile.builder().user(user2).companyName("Agency Two").businessRegistrationNumber("BR-002").officeAddress("Kandy").district("Kandy").contactPersonName("Jane").contactPersonPhone("+94772222222").kycStatus(KycStatus.PENDING_APPROVAL).build());
        agencyProfileRepository.save(AgencyProfile.builder().user(user3).companyName("Agency Three").businessRegistrationNumber("BR-003").officeAddress("Galle").district("Galle").contactPersonName("Bob").contactPersonPhone("+94773333333").kycStatus(KycStatus.APPROVED).build());

        Page<AgencyProfile> pendingPage = agencyProfileRepository.findByKycStatusIn(
                List.of(KycStatus.PENDING, KycStatus.PENDING_APPROVAL), PageRequest.of(0, 10));
        assertEquals(2, pendingPage.getTotalElements());

        Page<AgencyProfile> approvedPage = agencyProfileRepository.findByKycStatusIn(
                List.of(KycStatus.APPROVED), PageRequest.of(0, 10));
        assertEquals(1, approvedPage.getTotalElements());
        assertEquals("Agency Three", approvedPage.getContent().get(0).getCompanyName());
    }

    @Test
    @DisplayName("DriverProfileRepository.findByKycStatusIn filters drivers accurately")
    void testDriverFindByKycStatusIn() {
        User agencyUser = userRepository.save(User.builder().email("agency@test.com").phoneNumber("+94770000000").passwordHash("pass").role(Role.AGENCY).status(UserStatus.ACTIVE).build());
        AgencyProfile agency = agencyProfileRepository.save(AgencyProfile.builder().user(agencyUser).companyName("Express Logistics").businessRegistrationNumber("BR-999").officeAddress("Colombo").district("Colombo").contactPersonName("Manager").contactPersonPhone("+94770000000").kycStatus(KycStatus.APPROVED).build());

        User driverUser1 = userRepository.save(User.builder().email("driver1@test.com").phoneNumber("+94774444444").passwordHash("pass").role(Role.DRIVER).status(UserStatus.ACTIVE).build());
        User driverUser2 = userRepository.save(User.builder().email("driver2@test.com").phoneNumber("+94775555555").passwordHash("pass").role(Role.DRIVER).status(UserStatus.ACTIVE).build());

        driverProfileRepository.save(DriverProfile.builder().user(driverUser1).agency(agency).fullName("Sunil Driver").drivingLicenseNumber("DL-1001").licenseExpiryDate(LocalDate.now().plusYears(2)).nicNumber("123456789V").kycStatus(KycStatus.PENDING).build());
        driverProfileRepository.save(DriverProfile.builder().user(driverUser2).agency(agency).fullName("Nimal Driver").drivingLicenseNumber("DL-1002").licenseExpiryDate(LocalDate.now().plusYears(2)).nicNumber("987654321V").kycStatus(KycStatus.APPROVED).build());

        Page<DriverProfile> pendingDrivers = driverProfileRepository.findByKycStatusIn(
                List.of(KycStatus.PENDING), PageRequest.of(0, 10));
        assertEquals(1, pendingDrivers.getTotalElements());
        assertEquals("Sunil Driver", pendingDrivers.getContent().get(0).getFullName());
    }

    @Test
    @DisplayName("VehicleRepository.findByKycStatusIn filters vehicles accurately")
    void testVehicleFindByKycStatusIn() {
        User agencyUser = userRepository.save(User.builder().email("agencyv@test.com").phoneNumber("+94779999999").passwordHash("pass").role(Role.AGENCY).status(UserStatus.ACTIVE).build());
        AgencyProfile agency = agencyProfileRepository.save(AgencyProfile.builder().user(agencyUser).companyName("Cargo Express").businessRegistrationNumber("BR-888").officeAddress("Colombo").district("Colombo").contactPersonName("Manager").contactPersonPhone("+94779999999").kycStatus(KycStatus.APPROVED).build());

        vehicleRepository.save(Vehicle.builder().agency(agency).registrationNumber("WP-CAB-1111").makeAndModel("Isuzu Elf").capacity(BigDecimal.valueOf(3000)).cargoVolumeCbm(BigDecimal.valueOf(15)).vehicleType(VehicleType.TRUCK).kycStatus(KycStatus.PENDING_APPROVAL).build());
        vehicleRepository.save(Vehicle.builder().agency(agency).registrationNumber("WP-CAB-2222").makeAndModel("Toyota HiAce").capacity(BigDecimal.valueOf(1500)).cargoVolumeCbm(BigDecimal.valueOf(8)).vehicleType(VehicleType.VAN).kycStatus(KycStatus.APPROVED).build());

        Page<Vehicle> pendingVehicles = vehicleRepository.findByKycStatusIn(
                List.of(KycStatus.PENDING_APPROVAL), PageRequest.of(0, 10));
        assertEquals(1, pendingVehicles.getTotalElements());
        assertEquals("WP-CAB-1111", pendingVehicles.getContent().get(0).getRegistrationNumber());
    }
}
