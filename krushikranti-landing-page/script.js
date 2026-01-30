const hamburger = document.querySelector('.hamburger');
const navLinks = document.querySelector('.nav-links');

hamburger.addEventListener('click', () => {
    navLinks.classList.toggle('active');
});

document.addEventListener('DOMContentLoaded', function() {
    
    // --- Google Play Coming Soon Modal Logic ---

    const modal = document.getElementById("comingSoonModal");
    const btn = document.getElementById("googlePlayBtn");
    const closeSpan = document.querySelector(".close-btn");
    const okBtn = document.querySelector(".modal-ok-btn");

    // Check if elements exist to avoid errors on other pages
    if (btn && modal) {
        
        // Open Modal when Google Play button is clicked
        btn.addEventListener('click', function(e) {
            e.preventDefault(); // Prevents the link from jumping
            modal.style.display = "block";
        });

        // Close Modal when 'X' is clicked
        if (closeSpan) {
            closeSpan.addEventListener('click', function() {
                modal.style.display = "none";
            });
        }

        // Close Modal when 'OK' button is clicked
        if (okBtn) {
            okBtn.addEventListener('click', function() {
                modal.style.display = "none";
            });
        }

        // Close Modal when clicking outside the box
        window.addEventListener('click', function(e) {
            if (e.target === modal) {
                modal.style.display = "none";
            }
        });
    }
});