package com.nayasantha.api.user;

import com.nayasantha.api.common.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Entity
@Table(name = "users")
@Getter
@Setter
public class User extends BaseEntity {

    @Column(nullable = false, unique = true)
    private String mobile;

    @Column(unique = true)
    private String email;

    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status = Status.ACTIVE;

    @Enumerated(EnumType.STRING)
    @Column(name = "profile_completion_status", nullable = false)
    private ProfileCompletionStatus profileCompletionStatus = ProfileCompletionStatus.NEW;

    @Column(name = "last_login_at")
    private Instant lastLoginAt;

    public enum Status { ACTIVE, SUSPENDED, DELETED }
    public enum ProfileCompletionStatus { NEW, ONBOARDING, COMPLETE }
}
