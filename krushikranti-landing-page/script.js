const hamburger = document.querySelector('.hamburger');
const navLinks = document.querySelector('.nav-links');

hamburger.addEventListener('click', () => {
    navLinks.classList.toggle('active');
});

document.addEventListener('DOMContentLoaded', function() {
    
    // Hamburger menu toggle
    const hamburger = document.querySelector('.hamburger');
    const navLinks = document.querySelector('.nav-links');

    if (hamburger && navLinks) {
        hamburger.addEventListener('click', () => {
            navLinks.classList.toggle('active');
        });
    }

    // Download button - direct download (works for both local and production)
    const downloadBtn = document.getElementById("downloadApkBtn");
    
    if (downloadBtn) {
        // Optional: Add click tracking or analytics here if needed
        downloadBtn.addEventListener('click', function(e) {
            // The download will happen automatically via the href attribute
            // This is just for any additional tracking/logging
            console.log('Download button clicked - APK download initiated');
        });
    }
});