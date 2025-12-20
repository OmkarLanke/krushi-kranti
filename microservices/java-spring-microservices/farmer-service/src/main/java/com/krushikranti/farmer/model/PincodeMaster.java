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

    @Column(name = "village_hi", length = 200)
    private String villageHi;

    @Column(name = "village_mr", length = 200)
    private String villageMr;

    @Column(name = "taluka", nullable = false, length = 100)
    private String taluka;

    @Column(name = "taluka_hi", length = 100)
    private String talukaHi;

    @Column(name = "taluka_mr", length = 100)
    private String talukaMr;

    @Column(name = "district", nullable = false, length = 100)
    private String district;

    @Column(name = "district_hi", length = 100)
    private String districtHi;

    @Column(name = "district_mr", length = 100)
    private String districtMr;

    @Column(name = "state", nullable = false, length = 100)
    private String state;

    @Column(name = "state_hi", length = 100)
    private String stateHi;

    @Column(name = "state_mr", length = 100)
    private String stateMr;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}

