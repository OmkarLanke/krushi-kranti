package com.krushikranti.jobapplication.repository;

import com.krushikranti.jobapplication.domain.JobApplication;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface JobApplicationRepository extends JpaRepository<JobApplication, UUID> {

    List<JobApplication> findByCurrentStatus(String status);

    List<JobApplication> findByRoleType(String roleType);

    @Query("SELECT j FROM JobApplication j WHERE " +
           "(:status IS NULL OR j.currentStatus = :status) AND " +
           "(:roleType IS NULL OR j.roleType = :roleType) " +
           "ORDER BY j.submittedAt DESC")
    List<JobApplication> findWithFilters(
            @Param("status") String status,
            @Param("roleType") String roleType
    );

    /**
     * Find applications with filters and pagination.
     */
    @Query("SELECT j FROM JobApplication j WHERE " +
           "(:status IS NULL OR j.currentStatus = :status) AND " +
           "(:roleType IS NULL OR j.roleType = :roleType)")
    Page<JobApplication> findWithFiltersPaged(
            @Param("status") String status,
            @Param("roleType") String roleType,
            Pageable pageable
    );
}

