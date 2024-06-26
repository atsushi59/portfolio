document.addEventListener('turbo:load', function() {
    const stars = document.querySelectorAll('.star-rating label');
    const currentRating = parseInt(document.querySelector('input[name="review[rating]"]:checked')?.value || '<%= @review.rating %>', 10);

    stars.forEach((star, index) => {
        const ratingValue = index + 1;
        if (ratingValue <= currentRating) {
            star.classList.remove('text-gray-300');
            star.classList.add('text-yellow-400');
        }
    });

    stars.forEach((star, index) => {
        star.addEventListener('click', function() {
            const ratingValue = index + 1; 
            const allStars = this.parentElement.querySelectorAll('label');

            allStars.forEach((s, i) => {
                s.classList.remove('text-yellow-400');
                s.classList.add('text-gray-300');
                if (i < ratingValue) {
                    s.classList.remove('text-gray-300');
                    s.classList.add('text-yellow-400');
                }
            });
        });
    });
});
