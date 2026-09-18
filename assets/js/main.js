// Hogaria - interacciones ligeras del front-end (sin dependencias externas)

// Lee la paleta real de la app desde las variables CSS (nunca hardcodeada
// aqui), para que los graficos de Chart.js usen siempre los mismos colores
// que el resto de la interfaz. Devuelve tonos "solidos" para las barras/
// segmentos y "suaves" a juego para fondos si se necesitan.
function hgColoresGrafico() {
    var estilo = getComputedStyle(document.documentElement);
    function leer(variable) { return estilo.getPropertyValue(variable).trim(); }
    return {
        primario: leer('--hg-primary'),
        acento: leer('--hg-accent'),
        ok: leer('--hg-ok'),
        warn: leer('--hg-warn'),
        off: leer('--hg-off'),
        info: leer('--hg-info'),
        texto: leer('--hg-ink'),
        textoSuave: leer('--hg-ink-muted'),
        borde: leer('--hg-border'),
        // Paleta ciclica para graficos con mas categorias que colores base
        serie: [leer('--hg-primary'), leer('--hg-accent'), leer('--hg-ok'), leer('--hg-info'), leer('--hg-warn'), leer('--hg-off')]
    };
}

// Modal de confirmacion generico (reemplaza confirm() del navegador) para
// acciones irreversibles. Devuelve una promesa que resuelve true/false segun
// lo que elija el usuario. Se expone en window por si alguna pagina necesita
// llamarlo directamente ademas del cableado automatico de mas abajo.
function hgConfirmar(mensaje) {
    return new Promise(function (resolve) {
        var backdrop = document.createElement('div');
        backdrop.className = 'hg-modal-backdrop';

        var modal = document.createElement('div');
        modal.className = 'hg-modal';
        modal.setAttribute('role', 'alertdialog');
        modal.setAttribute('aria-modal', 'true');
        modal.setAttribute('aria-labelledby', 'hgModalTitulo');
        modal.innerHTML =
            '<div class="hg-modal__icono"><i class="bi bi-exclamation-triangle-fill"></i></div>' +
            '<h3 id="hgModalTitulo">Confirmar acción</h3>' +
            '<p></p>' +
            '<div class="hg-modal__acciones">' +
            '<button type="button" class="hg-btn hg-btn--ghost" data-hg-cancelar>Cancelar</button>' +
            '<button type="button" class="hg-btn hg-btn--peligro" data-hg-confirmar>Sí, continuar</button>' +
            '</div>';
        modal.querySelector('p').textContent = mensaje;
        backdrop.appendChild(modal);
        document.body.appendChild(backdrop);

        var focoPrevio = document.activeElement;

        function alEscape(evt) {
            if (evt.key === 'Escape') cerrar(false);
        }

        function cerrar(resultado) {
            document.removeEventListener('keydown', alEscape);
            backdrop.classList.add('is-leaving');
            backdrop.addEventListener('animationend', function () {
                backdrop.remove();
                if (focoPrevio && typeof focoPrevio.focus === 'function') focoPrevio.focus();
            }, { once: true });
            resolve(resultado);
        }

        backdrop.addEventListener('click', function (evt) {
            if (evt.target === backdrop) cerrar(false);
        });
        modal.querySelector('[data-hg-cancelar]').addEventListener('click', function () { cerrar(false); });
        modal.querySelector('[data-hg-confirmar]').addEventListener('click', function () { cerrar(true); });
        document.addEventListener('keydown', alEscape);

        // El foco por defecto queda en "Cancelar": si el usuario presiona
        // Enter sin querer, no dispara la accion destructiva.
        modal.querySelector('[data-hg-cancelar]').focus();
    });
}
window.hgConfirmar = hgConfirmar;

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

    // Confirmacion antes de acciones irreversibles: cualquier <form> con
    // data-confirmar="mensaje" pausa su envio y muestra el modal; solo se
    // envia de verdad si el usuario confirma. data-confirmar-si="campo:valor"
    // es opcional y limita la confirmacion a cuando ese campo del formulario
    // tiene ese valor exacto (ej. solo confirmar si el estado elegido es
    // "bloqueado", pero no para los demas cambios del mismo formulario).
    document.querySelectorAll('form[data-confirmar]').forEach(function (form) {
        form.addEventListener('submit', function (evt) {
            if (form.dataset.hgConfirmado === '1') { return; }

            var condicion = form.getAttribute('data-confirmar-si');
            if (condicion) {
                var partes = condicion.split(':');
                var campo = form.elements.namedItem(partes[0]);
                var valorActual = campo ? campo.value : null;
                if (valorActual !== partes[1]) { return; }
            }

            evt.preventDefault();
            hgConfirmar(form.getAttribute('data-confirmar')).then(function (confirmado) {
                if (confirmado) {
                    form.dataset.hgConfirmado = '1';
                    if (form.requestSubmit) form.requestSubmit(); else form.submit();
                }
            });
        });
    });
});
