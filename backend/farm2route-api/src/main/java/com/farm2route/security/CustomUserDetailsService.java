package com.farm2route.security;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String identifier) throws UsernameNotFoundException {
        try {
            UUID userId = UUID.fromString(identifier);
            return loadUserById(userId);
        } catch (IllegalArgumentException ex) {
            // Not a UUID, find by phone or email
            User user = userRepository.findByIdentifier(identifier)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found with phone/email: " + identifier));
            return new CustomUserPrincipal(user);
        }
    }

    @Transactional(readOnly = true)
    public UserDetails loadUserById(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with ID: " + id));
        return new CustomUserPrincipal(user);
    }
}
