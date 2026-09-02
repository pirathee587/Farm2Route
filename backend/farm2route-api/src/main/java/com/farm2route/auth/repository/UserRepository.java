package com.farm2route.auth.repository;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByPhoneNumber(String phoneNumber);

    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u WHERE u.phoneNumber = :identifier OR (u.email IS NOT NULL AND u.email = :identifier)")
    Optional<User> findByIdentifier(@Param("identifier") String identifier);

    boolean existsByPhoneNumber(String phoneNumber);

    boolean existsByEmail(String email);

    List<User> findByRole(Role role);
}
