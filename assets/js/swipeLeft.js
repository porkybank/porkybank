function debounce(fn, delay) {
  let timer = null;
  return function () {
    const context = this;
    const args = arguments;
    clearTimeout(timer);
    timer = setTimeout(() => {
      fn.apply(context, args);
    }, delay);
  };
}

const swipeLeft = () => {
  return {
    mounted() {
      const getTouches = (evt) => {
        return evt.touches || evt.originalEvent.touches;
      };

      const handleTouchStart = (evt) => {
        const firstTouch = getTouches(evt)[0];
        xDown = firstTouch.clientX;
        yDown = firstTouch.clientY;
      };

      const handleTouchMove = (evt) => {
        if (!xDown || !yDown) {
          return;
        }

        var xUp = evt.touches[0].clientX;
        var yUp = evt.touches[0].clientY;

        var xDiff = xDown - xUp;
        var yDiff = yDown - yUp;

        if (Math.abs(xDiff) > Math.abs(yDiff)) {
          /* Most significant */
          if (xDiff > 10) {
            /* Left swipe */
            this.el.querySelector(".value").classList.add("!-left-6");
            this.el.querySelector(".icon").classList.add("opacity-100");
            setTimeout(() => {
              const confirmed = window.confirm(
                this.el.dataset.confirmSwipe ||
                  "Are you sure you want to delete this item?"
              );
              if (confirmed) {
                this.pushEventTo(this.el, "swipe_left", {
                  id: this.el.id,
                });
              } else {
                this.el.querySelector(".value").classList.remove("!-left-6");
                this.el.querySelector(".icon").classList.remove("opacity-100");
              }
            }, 500);
          }
          // else { Right swipe }
        }
        // else { Up or down swipe }

        /* Reset values */
        xDown = null;
        yDown = null;
      };

      debouncedTouchMove = debounce(handleTouchMove, 100);

      this.el.addEventListener("touchstart", handleTouchStart, false);
      this.el.addEventListener("touchmove", debouncedTouchMove, false);

      var xDown = null;
      var yDown = null;
    },
  };
};

export default swipeLeft;
