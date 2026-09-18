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

    // Mostrar/ocultar contrasena
    document.querySelectorAll('[data-toggle-password]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            var input = document.getElementById(btn.getAttribute('data-toggle-password'));
            var icon = btn.querySelector('i');
            if (!input) { return; }
            var oculto = input.type === 'password';
            input.type = oculto ? 'text' : 'password';
            if (icon) {
                icon.classList.toggle('bi-eye', !oculto);
                icon.classList.toggle('bi-eye-slash', oculto);
            }
            btn.setAttribute('aria-label', oculto ? 'Ocultar contrasena' : 'Mostrar contrasena');
        });
    });

    // Menu de la cuenta (avatar): recuadro propio simple, sin modal de
    // Bootstrap ni backdrop. Se abre/cierra alternando una clase; se cierra
    // al hacer clic afuera o al presionar Escape.
    var cuenta = document.getElementById('hg-cuenta');
    if (cuenta) {
        var cuentaBtn = document.getElementById('hg-avatar-trigger');
        cuentaBtn.addEventListener('click', function (evt) {
            evt.stopPropagation();
            var abierto = cuenta.classList.toggle('is-open');
            cuentaBtn.setAttribute('aria-expanded', abierto ? 'true' : 'false');
        });
        document.addEventListener('click', function (evt) {
            if (!cuenta.contains(evt.target)) {
                cuenta.classList.remove('is-open');
                cuentaBtn.setAttribute('aria-expanded', 'false');
            }
        });
        document.addEventListener('keydown', function (evt) {
            if (evt.key === 'Escape') {
                cuenta.classList.remove('is-open');
                cuentaBtn.setAttribute('aria-expanded', 'false');
            }
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
