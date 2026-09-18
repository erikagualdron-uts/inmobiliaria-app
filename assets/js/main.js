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

    // Convierte el banner de exito ya renderizado (patron Post/Redirect/Get)
    // en una notificacion flotante tipo toast que se autodescarta, en vez de
    // quedar fijo arriba del contenido. Los banners de error con listas de
    // validacion se dejan como estan: el usuario necesita verlos mientras
    // corrige el formulario debajo, asi que no conviene que desaparezcan solos.
    var alertaExito = document.querySelector('.hg-alert--success');
    if (alertaExito) {
        var contenedorToasts = document.createElement('div');
        contenedorToasts.className = 'hg-toast-container';
        document.body.appendChild(contenedorToasts);

        var toast = document.createElement('div');
        toast.className = 'hg-toast';
        toast.setAttribute('role', 'status');
        toast.innerHTML =
            '<i class="bi bi-check-circle-fill hg-toast__icon"></i>' +
            '<span class="hg-toast__texto"></span>' +
            '<button type="button" class="hg-toast__cerrar" aria-label="Cerrar">&times;</button>';
        toast.querySelector('.hg-toast__texto').textContent = alertaExito.textContent.trim();
        contenedorToasts.appendChild(toast);
        alertaExito.remove();

        var cerrarToast = function () {
            toast.classList.add('is-leaving');
            toast.addEventListener('animationend', function () { toast.remove(); }, { once: true });
        };
        var temporizadorToast = setTimeout(cerrarToast, 4500);
        toast.querySelector('.hg-toast__cerrar').addEventListener('click', function () {
            clearTimeout(temporizadorToast);
            cerrarToast();
        });
    }

    // Botones con estado de carga: al enviar un formulario marcado con
    // "js-form-cargando", su boton de submit se deshabilita y muestra un
    // spinner mientras procesa, para evitar el doble envio. Se dispara en
    // el evento "submit" real, que solo ocurre si ya paso la validacion
    // HTML5 del formulario.
    document.querySelectorAll('form.js-form-cargando').forEach(function (form) {
        form.addEventListener('submit', function () {
            var boton = form.querySelector('button[type="submit"]');
            if (!boton || boton.disabled) return;
            boton.disabled = true;
            boton.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Procesando...';
        });
    });
});
