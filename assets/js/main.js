// Hogaria - interacciones ligeras del front-end (sin dependencias externas)
document.addEventListener('DOMContentLoaded', function () {

    // Sombra en el navbar al hacer scroll
    var navbar = document.getElementById('hg-navbar');
    if (navbar) {
        var onScroll = function () {
            if (window.scrollY > 8) {
                navbar.classList.add('is-scrolled');
            } else {
                navbar.classList.remove('is-scrolled');
            }
        };
        onScroll();
        window.addEventListener('scroll', onScroll, { passive: true });
    }

    // Menu movil
    var toggle = document.getElementById('hg-navbar-toggle');
    var menu = document.getElementById('hg-navmenu');
    if (toggle && menu) {
        toggle.addEventListener('click', function () {
            var isOpen = menu.classList.toggle('is-open');
            toggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
        });
        // Cierra el menu movil al elegir una opcion
        menu.querySelectorAll('a').forEach(function (link) {
            link.addEventListener('click', function () { menu.classList.remove('is-open'); });
        });
    }

    // El buscador exige al menos un criterio antes de enviar
    var searchForm = document.getElementById('hg-search-form');
    if (searchForm) {
        searchForm.addEventListener('submit', function (evt) {
            var data = new FormData(searchForm);
            var tieneCriterio = ['ciudad', 'tipo', 'operacion'].some(function (campo) {
                return (data.get(campo) || '').trim().length > 0;
            });
            if (!tieneCriterio) {
                evt.preventDefault();
                var hint = searchForm.querySelector('.hg-search__hint');
                if (hint) { hint.hidden = false; }
            }
        });
    }
});
