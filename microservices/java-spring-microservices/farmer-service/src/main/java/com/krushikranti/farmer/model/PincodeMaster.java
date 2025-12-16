package com.krushikranti.farmer.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "pincode_master", 
       uniqueConstraints = @UniqueConstraint(columnNames = {"pincode", "village"}))
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PincodeMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "pincode_id")
    private Long id;

    @Column(name = "pincode", nullable = false, length = 6)
    private String pincode;

    @Column(name = "village", nullable = false, length = 200)
    private String village;

    @Column(name = "taluka", nullable = false, length = 100)
    private String taluka;

    @Column(name = "district", nullable = false, length = 100)
    private String district;

    @Column(name = "state", nullable = false, length = 100)
    private String state;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}

