# Primeros pasos

## Bienvenida {#bienvenue}

Kastideo reúne en una sola interfaz sus **canales en directo, películas y series IPTV**, sus **vídeos personales** (disco, memoria USB, NAS, Jellyfin, Emby, Plex) y **YouTube**. Kastideo **no proporciona ningún contenido**: usted añade sus propias fuentes.

<!--mac-->
![La pantalla de inicio](img:home)

1. Volver al inicio, desde cualquier lugar.
2. Una sola búsqueda para canales, películas y series.
3. El botón **?**: la ayuda, abierta en la página que corresponde a la pantalla en la que se encuentra.
<!--/mac-->
<!--pc-->
![La pantalla de inicio](img:homepc)

1. El botón **?**: la ayuda, abierta en la página que corresponde a la pantalla en la que se encuentra.
2. **Registro de reproducción**: la herramienta de diagnóstico.
3. **Ajustes**: fuentes, apariencia, grabaciones…
4. Una sola búsqueda para canales, películas y series, y después los mosaicos y los accesos directos ([detalle de la pantalla de inicio](help:accueil)).
<!--/pc-->

### Inicio rápido

<!--mac-->
1. En el primer inicio, haga clic en **Añadir una fuente** (o **Ajustes ⌘,** > **Fuentes** > **Añadir**).
<!--/mac-->
<!--pc-->
1. Abra **Ajustes** (el engranaje del inicio, o **Ctrl+,**) > **Fuentes** > **Añadir una fuente**.
<!--/pc-->
2. Elija el tipo de fuente: [Xtream Codes](help:xtream), [lista M3U](help:m3u), [Carpetas](help:dossiers) o un servidor [Jellyfin, Emby o Plex](help:serveurs).
3. Rellene los datos solicitados y haga clic en **Añadir**: Kastideo carga los canales, las películas, las series y la [guía de TV](help:guide).
4. Vuelva al **Inicio** y abra **En directo**, **Películas** o **Series**.

### Obtener ayuda

<!--mac-->
- El botón **?** de la barra de herramientas abre la ayuda en la página que corresponde a la pantalla actual.
- Menú **Ayuda > Ayuda de Kastideo** o **⌘?**.
<!--/mac-->
<!--pc-->
- El botón **?** del inicio y de las pantallas principales abre la ayuda.
<!--/pc-->
- El campo **Buscar** en la parte superior de la ayuda busca en todas las páginas.
- ¿Algo no funciona? Consulte las [preguntas frecuentes](help:faq) y después la [resolución de problemas](help:depannage).

> ¿Quiere ver YouTube? Consulte [YouTube](help:youtube). Para importar sus suscripciones: [paso a paso](help:youtube-import).

## Preguntas frecuentes {#faq}

### ¿Dónde encuentro canales para añadir?
Kastideo no proporciona ni canales ni suscripciones. Su proveedor de IPTV le da un servidor, un nombre de usuario y una contraseña ([Xtream Codes](help:xtream)), o la dirección de una lista de reproducción ([M3U](help:m3u)). También puede reproducir sus propios archivos ([Carpetas](help:dossiers)).

### ¿Cómo cambio el idioma de Kastideo?
Kastideo está disponible en **francés, inglés, español, alemán, italiano y portugués** (Portugal y Brasil). Por defecto sigue el idioma de su dispositivo; si ese idioma no es compatible, la interfaz se muestra en inglés. Para cambiarlo: **Ajustes > General > Idioma** (en iPhone, iPad y Apple TV, Kastideo sigue el idioma del sistema: configúrelo en los Ajustes del dispositivo). El cambio se aplica la próxima vez que se inicie Kastideo.

### Un canal no arranca o va a saltos
<!--mac-->Consulte [Si un canal no arranca](help:chaine-ne-demarre-pas) y [Resolución de problemas](help:depannage).<!--/mac--><!--pc-->Consulte [Resolución de problemas](help:depannage).<!--/pc--> Muy a menudo la causa es una **segunda conexión simultánea** en la misma suscripción: consulte [Una sola conexión a la vez](help:connexion-unique).

### La guía de TV está vacía o incompleta
Ajustes > Fuentes > **Recargar la guía de TV**, y después consulte [Guía TV](help:guide) y la [guía de respaldo](help:guide-secours).

### ¿Cómo puedo ver YouTube sin anuncios?
Kastideo reproduce los vídeos con el reproductor oficial en **modo de privacidad mejorada**: sin cookies de seguimiento, por lo que normalmente no hay anuncios personalizados. **No** es un bloqueador de anuncios: consulte [Anuncios, cuenta y privacidad](help:youtube-confidentialite).

### ¿Cómo importo mis suscripciones de YouTube?
YouTube no permite conectar una cuenta a una aplicación de terceros: se usa un archivo que Google genera para usted. Siga la [guía paso a paso](help:youtube-import).

### La búsqueda de YouTube pide una clave
La búsqueda utiliza **su propia** clave de API de Google gratuita. La [guía paso a paso](help:youtube-cle) la explica en pocos minutos. Sin clave, puede seguir canales y reproducir enlaces pegados.

### ¿Cómo grabo un programa?
Consulte [Grabar la televisión en directo](help:enregistrer) y [Programar una grabación](help:programmer).

### ¿Cómo veo un programa que ya se emitió?
Si su proveedor ofrece un archivo: consulte [Replay](help:replay).

### ¿Cómo llevo mis ajustes a otro ordenador?
Consulte [Copia de seguridad y transferencia](help:sauvegarde).

# Fuentes

## Xtream Codes {#xtream}

<!--mac-->
Es el formato más habitual entre los proveedores de IPTV. Necesita tres datos: la dirección del **servidor** (por ejemplo `http://example.com:8080`), su **nombre de usuario** y su **contraseña**.

- El botón **Probar la conexión** comprueba sus credenciales y muestra el estado de la cuenta, su fecha de caducidad y el número de conexiones simultáneas permitidas.
- La contraseña se guarda en el **llavero de macOS**, nunca en texto plano en el disco.
- La guía de TV del servidor se utiliza automáticamente.
- Las series se abren en una página con sus temporadas y episodios.
<!--/mac-->

<!--pc-->
Dirección del servidor (p. ej. http://example.com:8080), nombre de usuario y contraseña. La contraseña se guarda en el almacén seguro del sistema: Administrador de credenciales en Windows, GNOME Keyring o KWallet en Linux.
<!--/pc-->

## Lista M3U / M3U8 {#m3u}

<!--mac-->
- **Por URL**: pegue la dirección de la lista que le haya facilitado su proveedor.
- Si la dirección tiene el aspecto `get.php?username=…&password=…` (el caso más habitual con los proveedores de suscripción), Kastideo la reconoce y la guarda como **Xtream Codes**: la carga es mucho más rápida, la guía de TV está incluida y la contraseña se guarda en el llavero. Las fuentes de este tipo ya guardadas se convierten automáticamente.
- **Por archivo**: elija un archivo `.m3u` o `.m3u8` en su Mac. Kastideo conserva el permiso de acceso para poder actualizarlo.
- Las categorías proceden del atributo `group-title`, los logotipos de `tvg-logo` y el enlace con la guía de TV de `tvg-id`.
- Kastideo clasifica automáticamente las entradas en En directo, Películas o Series según su dirección.
<!--/mac-->

<!--pc-->
Dirección de la lista o archivo en el disco (**Elegir un archivo…**). Una dirección «get.php?username=…&password=…» se reconoce y se convierte en una fuente Xtream, mucho más rápida y completa (fichas, episodios, últimas novedades).
<!--/pc-->

## Carpetas (disco, memoria USB, NAS) {#dossiers}

<!--mac-->
Para ver vídeos almacenados en el Mac, en un disco externo, en una memoria USB o en un NAS:

1. Ajustes > Fuentes > **Añadir** > tipo **Carpetas (disco, USB, NAS)**.
2. **Añadir una carpeta…**: elija una o varias carpetas (por ejemplo «Películas» y «Series»). Para un **NAS**, monte primero el recurso compartido en el Finder (**Ir > Conectarse al servidor…**, por ejemplo `smb://nas.local/Videos`) y después elíjalo entre los volúmenes.
3. **Añadir**: Kastideo analiza las carpetas y sus subcarpetas.

Los vídeos se reconocen por su nombre:

- **Películas**: «Inception (2010).mkv», «The.Matrix.1999.1080p.BluRay.mkv», o una carpeta «Amélie (2001)» que contenga la película. Aparecen en **Películas**, categoría «Películas · nombre de la carpeta».
- **Series**: «Breaking.Bad.S01E02.mkv», «Friends 1x05.mp4», o una carpeta «Kaamelott/Season 3/12 - Le Tourment.avi». Los episodios se agrupan en una serie, con sus temporadas, en **Series**.
- **Otros vídeos** (vacaciones, cámara…): categoría **Vídeos · nombre de la carpeta**, en Películas.

Las carpetas se analizan en cada inicio y después cada 20 minutos: un vídeo nuevo aparece solo. Si el disco está desconectado o el recurso compartido desconectado, un mensaje lo indica bajo la fuente y se conserva la lista anterior. Los **subtítulos** colocados junto a un vídeo («Inception (2010).srt», «Inception (2010).en.srt») se cargan al reproducir.

Con una **clave TMDB** (Ajustes > General), las películas y series obtienen automáticamente un **póster y una sinopsis**. Si el nombre del archivo confunde la búsqueda, haga clic con el botón derecho en el póster (o en el enlace al final de la página de detalles) > **Corregir la ficha…**: busque el título correcto y selecciónelo; la elección se recuerda.
<!--/mac-->

<!--pc-->
Ajustes > Fuentes > **Añadir una fuente** > **Carpetas**, y después **Añadir una carpeta…** (disco interno, disco o memoria USB) o escriba una **ruta de red** y haga clic en **+**: `\\NAS\Videos` o una unidad de red (`Z:\`) en Windows, un recurso compartido montado (`/mnt/nas/videos`, `/media/…`) en Linux. Varias carpetas pueden formar una sola fuente.

- **Películas** reconocidas por su nombre: «Inception (2010).mkv», «The.Matrix.1999.1080p.BluRay.mkv», carpeta «Amélie (2001)». Categoría «Películas · nombre de la carpeta».
- **Series**: «Breaking.Bad.S01E02.mkv», «Friends 1x05.mp4», carpetas «Serie/Season 1/…». Los episodios se agrupan por serie y temporada en **Series**.
- **Otros vídeos**: categoría **Vídeos · nombre de la carpeta** en Películas.
- Se analizan en cada inicio y después cada 20 minutos. Disco desconectado: un mensaje lo indica y se conserva la lista anterior. Las subcarpetas ilegibles («System Volume Information»…) se omiten.
- Los **subtítulos** colocados junto a un vídeo («Película.srt», «Película.en.srt») se cargan al reproducir.
- Con una **clave TMDB**, los **pósteres y sinopsis** se añaden automáticamente; clic derecho > **Corregir la ficha…** para elegir el título correcto cuando el nombre del archivo confunde la búsqueda.
<!--/pc-->

## Jellyfin, Emby y Plex {#serveurs}

<!--mac-->
### Jellyfin y Emby

1. Ajustes > Fuentes > **Añadir** > **Jellyfin** o **Emby**.
2. **Buscar en la red** encuentra los servidores de su casa; haga clic en el suyo para rellenar la dirección. Si no, escríbala (por ejemplo `192.168.1.10`: se añade el puerto 8096).
3. Su **nombre de usuario** y **contraseña** de Jellyfin / Emby — **opcionales**: déjelos vacíos si la cuenta no los tiene (una **clave de API** del panel de control también puede sustituirlos). **Probar la conexión** comprueba la dirección. Una dirección copiada del navegador («…:8096/web/index.html#!/home») se reduce a la del servidor.
4. **Añadir**: se comprueba el nombre de usuario y después las bibliotecas de películas, series y vídeos del servidor aparecen en **Películas** y **Series** (categorías «nombre de la biblioteca · nombre del servidor»), con los pósteres y detalles del servidor.

La reproducción es **directa**, sin transcodificación por parte del servidor. La contraseña y la sesión se guardan en el llavero.

### Plex

1. Ajustes > Fuentes > **Añadir** > **Plex**.
2. **Iniciar sesión con Plex** abre plex.tv en el navegador: inicie sesión y autorice a Kastideo. De vuelta en Kastideo, elija el servidor de su cuenta.
3. También puede escribir la dirección del servidor (puerto 32400) y su **token** (X-Plex-Token). El token es **opcional** si el servidor permite la red local sin autenticación (Plex > Ajustes > Red > «Lista de direcciones IP y redes permitidas sin autenticación»).
4. **Añadir**: las bibliotecas de películas y series aparecen en **Películas** y **Series**.
<!--/mac-->

<!--pc-->
Ajustes > Fuentes > **Añadir una fuente** > **Jellyfin**, **Emby** o **Plex**. **Buscar en la red** encuentra los servidores de su casa: haga clic en el suyo para rellenar el formulario (si no, escriba la dirección; sin puerto, se añade 8096 o 32400).

- **Jellyfin / Emby**: nombre de usuario y contraseña — **opcionales** si la cuenta no los tiene (o una **clave de API** del panel de control). **Probar** comprueba la dirección; si falla, se muestra la respuesta exacta del servidor.
- **Plex**: **Iniciar sesión con Plex** abre plex.tv en el navegador; autorice a Kastideo y después elija el servidor de su cuenta. O escriba la dirección y el **token** (X-Plex-Token), opcional si el servidor permite la red local sin autenticación.
- Las bibliotecas aparecen en **Películas** y **Series** («nombre de la biblioteca · nombre del servidor»), con los pósteres, detalles, temporadas y episodios del servidor. Reproducción directa, sin transcodificación.
- **Reanudación y «visto» compartidos en ambos sentidos**: la posición se envía al servidor mientras ve el contenido y se recupera la de sus otros dispositivos. Clic derecho > **Marcar como visto / no visto**; insignia **Visto** en los pósteres.

> Cortafuegos de Windows: en la primera búsqueda, permita a Kastideo en las redes privadas para que los servidores puedan responder.
<!--/pc-->

## Reanudación y «visto» compartidos con los servidores {#reprise-serveurs}

<!--mac-->
Con Jellyfin, Emby y Plex, la posición de reproducción se envía al servidor mientras usted ve el contenido: una película empezada en Kastideo puede reanudarse en el televisor, y a la inversa. Una película vista hasta el final se marca como **vista** en el servidor. Clic derecho en una película o un episodio > **Marcar como visto / no visto** (también para archivos de carpetas). Aparece una insignia **Visto** en los pósteres y una marca de verificación en la lista de episodios.

> Búsqueda en la red: la primera vez, macOS pide permiso para acceder a la **red local**; acéptelo (si no, Ajustes del Sistema > Privacidad y seguridad > Red local).
<!--/mac-->

## Guía TV (XMLTV) {#guide}

<!--mac-->
Cada fuente puede tener una dirección de guía de TV en formato XMLTV (`.xml` o `.xml.gz`). Si la deja vacía, Kastideo usa la del servidor Xtream o la anunciada en la lista (`url-tvg`). La guía se conserva desde 6 horas atrás hasta 48 horas por delante.
<!--/mac-->

<!--pc-->
La guía que proporciona su proveedor se carga en segundo plano y se guarda en el disco. El campo opcional **Guía TV (XMLTV)** de una fuente permite usar otra guía (.xml o .xml.gz).
<!--/pc-->

## Guía TV de respaldo (xmltvfr.fr) {#guide-secours}

<!--mac-->
La guía de su proveedor puede estar incompleta o vacía temporalmente. Kastideo la completa con una **guía de respaldo** gratuita de **xmltvfr.fr** (guía «Completa» por defecto: unos 785 canales franceses y extranjeros, 5 días, actualizada a diario):

- solo se completan los canales **sin programas** en su proveedor; la guía del proveedor mantiene la prioridad;
- los canales se asocian **por nombre**: «|FR| TF1 FHD» → TF1, «|FR| FRANCE 2 UHD» → France 2, «|FR| TF1 4K» → TF1 4K;
- la guía de respaldo se recarga cada 12 horas. Si el proveedor envía una guía vacía o ilegible, se conservan los programas ya conocidos y aparece un mensaje bajo la fuente.

**Saber de dónde procede la guía.** Bajo cada fuente, Ajustes > Fuentes muestra cuántos programas ha enviado el proveedor. El botón **Recargar la guía de TV** (icono de calendario) reinicia la descarga de la guía del proveedor y de la guía de respaldo. Las líneas del proveedor que son solo **separadores de categoría** («♣♦♣---|FR| FRANCE FHD |FR|---♣♦♣») se ignoran; una versión 4K o FHD sin programación propia reutiliza la de la versión HD; los canales sin programación muestran «Programa no disponible». El **Registro**, tema **Guía TV**, detalla cada intento: dirección solicitada, respuesta del servidor (código, tamaño, tiempo), número de canales y programas recibidos, periodo cubierto, cuántos de sus canales están vinculados a la guía del proveedor, a la guía de respaldo o a ninguna y, si la guía no contiene nada utilizable, el principio de la respuesta del servidor.

Ajustes > General > **Guía TV de respaldo**: actívela o desactívela, elija otra guía de xmltvfr.fr (Francia ~400 canales, TDT) o introduzca cualquier dirección XMLTV, **Actualizar ahora**, y vea cuántos canales se han vinculado a los suyos.
<!--/mac-->

<!--pc-->
Ajustes > General > **Guía TV**: una guía de respaldo rellena los canales sin programas en la guía de su proveedor, asociándolos por nombre. Elija una guía de xmltvfr.fr o escriba una dirección; **Recargar la guía** vuelve a descargarlo todo. El botón **Registro de la guía de TV** abre el Registro en el tema *Guía TV*: dirección solicitada, respuesta del proveedor (código, tamaño, tiempo), canales y programas recibidos, periodo cubierto, cuántos de sus canales están vinculados al proveedor, a la guía de respaldo o a ninguna guía y, si la guía no se puede usar, el principio de la respuesta del servidor. Los programas del proveedor se filtran según los identificadores de sus canales: si la guía contiene programas pero ninguno para sus canales, el registro muestra los identificadores de ambos lados.
<!--/pc-->

## Gestionar las fuentes {#gerer-sources}

<!--mac-->
Abra **Kastideo > Ajustes… (⌘,)**, pestaña **Fuentes**, o haga clic en el botón **Fuentes** de la barra de herramientas.

- El interruptor activa o desactiva una fuente sin eliminarla.
- Los botones permiten actualizar, editar o eliminar una fuente.
- Si hay un error, el mensaje aparece en rojo bajo la fuente y se muestra un triángulo naranja en la barra lateral.
<!--/mac-->

<!--pc-->
Ajustes > **Fuentes**: **edite** una fuente (botón del lápiz: nombre, servidor, usuario, contraseña, dirección de la lista, guía de TV — se conservan los favoritos, los recientes y las correcciones de canales), actualícela, elimínela y consulte el estado de su guía de TV. El botón del **ojo** muestra la contraseña (o la clave TMDB) para que pueda comprobarla. Las fuentes se actualizan al iniciar cuando su última actualización tiene más de 6 horas (ajustable). Si una actualización devuelve una sección vacía, se conserva la anterior.
<!--/pc-->

Mientras se comprueban o descargan los canales, películas y series de una suscripción (y cuando se recalculan las listas tras cambiar las categorías), aparece un banner **Actualizando el catálogo** en la parte superior de la pantalla. La aplicación puede parecer bloqueada unos segundos, o hasta un minuto con un catálogo grande: es normal y el banner desaparece solo.

# Navegar

## La pantalla de inicio {#accueil}

<!--mac-->
![La pantalla de inicio](img:home)

Kastideo se abre en la pantalla de **Inicio**, que contiene, de arriba abajo:

- el **campo de búsqueda**, que busca canales, películas y series a la vez; al hacer clic en un resultado se abre;
- los grandes mosaicos **En directo**, **Películas** y **Series**, y **Mis vídeos** en cuanto existe una fuente de [Carpetas, Jellyfin, Emby o Plex](help:mes-videos); cada mosaico muestra el número de canales, películas, series o vídeos;
- los botones **Favoritos**, **Recientes**, **Guía TV**, **YouTube** y **Grabaciones** (una insignia indica el número de elementos, o de grabaciones y descargas pendientes);
- la fila **Ahora en TV**: etiquetas por tema (Deportes, Noticias, Películas…) y **Esta noche**, que abren [el directo por temas](help:direct-theme);
- la fila **Continuar viendo**: las películas y episodios que ha empezado; un clic reanuda donde lo dejó;
- si algo se está reproduciendo, un banner **En reproducción** permite **volver** a ello o **detenerlo**.

Para volver al Inicio en cualquier momento: el botón **Inicio** (casa) en la parte superior izquierda de la barra de herramientas, **⌘0**, la fila **Inicio** de la barra lateral o la tecla **H** en la interfaz TV.

El **número de versión** se muestra discretamente abajo a la derecha, junto a los botones **?** e **Invítame a un café**; al hacer clic en la versión se abren las novedades.
<!--/mac-->
<!--pc-->
![La pantalla de inicio](img:homepc)

Kastideo se abre en la pantalla de **Inicio**, que contiene, de arriba abajo:

- la **cabecera**: logotipo, nombre y, a la derecha, tres botones: **Ayuda** (**F1**), **Registro de reproducción** y **Ajustes** (**Ctrl+,**); un pequeño indicador gira mientras se actualizan las fuentes;
- el **campo de búsqueda**, que busca canales, películas y series a la vez; al hacer clic en un resultado se abre;
- los grandes mosaicos **En directo**, **Películas** y **Series**, y **Mis vídeos** en cuanto existe una fuente de [Carpetas, Jellyfin, Emby o Plex](help:mes-videos); cada mosaico muestra el número de canales, películas, series o vídeos;
- los botones **Favoritos**, **Recientes**, **Guía TV**, **MultiVista**, **YouTube** y **Grabaciones** (una insignia indica el número de elementos, de canales en MultiVista, o de grabaciones y descargas pendientes);
- la fila **Continuar viendo**: las películas y episodios que ha empezado; un clic reanuda donde lo dejó;
- si algo se está reproduciendo, un banner **En reproducción** permite **volver** a ello o **detenerlo**;
- si no se ha añadido ninguna fuente, una tarjeta **Ninguna fuente** ofrece **Añadir una fuente**.

Abajo a la derecha: el botón **Invítame a un café** (se puede ocultar en Ajustes > Acerca de) y el número de versión.

Para volver al Inicio en cualquier momento: la fila **Inicio** de la barra lateral, **Ctrl+0** o la tecla **H** en la interfaz TV.

**En teléfonos y tabletas Android**, el Inicio se adapta al ancho de la pantalla: por debajo de unos 720 px (teléfono, o tableta en vertical), los cuatro mosaicos pasan a **dos columnas** y la cabecera se reduce. **En Android TV**, los botones se eligen con el mando a distancia (contorno visible) y **OK** abre.
<!--/pc-->

## Mis vídeos {#mes-videos}

<!--mac-->
En cuanto existe una fuente de **Carpetas**, **Jellyfin**, **Emby** o **Plex**, aparece un mosaico **Mis vídeos** en la pantalla de inicio (y una fila en la barra lateral, **⌘8**). Reúne sus vídeos, aparte del IPTV:

- **Destacado**: **Reanudar la reproducción** (películas y episodios empezados), **Añadidos recientemente**, **Películas por ver**, y después una fila de Películas, Series y Vídeos;
- **Películas**, **Series**, **Vídeos**: cuadrículas con búsqueda, filtros (**género**, **año**, **no visto**) y orden (título, añadidos recientemente, año);
- **Carpetas**: explore sus carpetas y subcarpetas como en el Finder (ruta de navegación para volver atrás), y las bibliotecas de los servidores;
- **Fuentes**: todas, o solo una (NAS, Emby, Plex…). Un triángulo naranja señala un error: clic derecho > **Detalles del error…** muestra la solicitud y la **respuesta exacta del servidor** (botón **Copiar**), y después **Reintentar**.

En **Películas** y **Series**, el selector **Todo / IPTV / Mis vídeos** (barra lateral, sobre las categorías) elige lo que se muestra: solo IPTV (por defecto), solo sus vídeos, o ambos mezclados. Las categorías de sus vídeos nunca se ocultan con el ajuste de países.
<!--/mac-->

<!--pc-->
En cuanto existe una fuente de **Carpetas**, **Jellyfin**, **Emby** o **Plex**, aparece un mosaico **Mis vídeos** en la pantalla de inicio (atajo **Ctrl+8**). Reúne sus vídeos, aparte del IPTV:

- **Destacado**: **Reanudar la reproducción** (películas y episodios empezados), **Añadidos recientemente**, **Películas por ver**, y después una fila de Películas, Series y Vídeos;
- **Películas**, **Series**, **Vídeos**: cuadrículas con búsqueda, filtros (**género**, **año**, **no visto**) y orden (título, añadidos recientemente, año);
- **Carpetas**: explore sus carpetas y subcarpetas como en el explorador de archivos (ruta de navegación para volver atrás), y las bibliotecas de los servidores;
- **Fuentes**: todas, o solo una (NAS, Emby, Plex…). Un triángulo naranja señala un error: clic derecho > **Detalles del error…** muestra la solicitud y la **respuesta exacta del servidor**, y después **Reintentar**.

En **Películas** y **Series**, el selector **Todo / IPTV / Mis vídeos** (barra lateral, sobre las categorías) elige lo que se muestra: solo IPTV (por defecto), solo sus vídeos, o ambos mezclados. Las categorías de sus vídeos nunca se ocultan con el ajuste de países.
<!--/pc-->

## Quitar un elemento de «Continuar viendo» {#retirer-reprise}

<!--mac-->
Haga clic con el botón derecho en una miniatura de **Continuar viendo** (inicio, interfaz Cine, Mis vídeos; pulsación larga en Android) para obtener:

- **Quitar de «Continuar viendo»**: la miniatura desaparece de la fila, pero la **posición se conserva**: cuando vuelva a reproducir la película, se reanudará donde la dejó.
- **Vaciar «Continuar viendo»**: elimina todas las miniaturas de la fila.

Un banner **Deshacer** permanece visible unos segundos. Un elemento quitado **vuelve** a la fila en cuanto lo vuelve a ver; mientras tanto aparece en «Vistos recientemente».
<!--/mac-->

## Ordenar y filtrar Mis vídeos {#filtres-videos}

<!--pc-->
En **Windows, Linux y Android**, el botón de **flecha** invierte el orden y **Agrupar por** reúne los carteles en **secciones** (fuente, categoría / carpeta / álbum, tipo, año, mes de adición; varios criterios a la vez). Todo se recuerda.
<!--/pc-->

En **Mis vídeos**, las vistas **Películas**, **Series** y **Vídeos** tienen una barra de filtros. Sus elecciones se **recuerdan** y se restauran en el siguiente inicio. **Restablecer** borra todos los filtros (se conserva el orden).

- **Fuente**: cuando hay varias fuentes añadidas (carpeta local, Emby, Jellyfin, Plex…), muestre solo una de ellas. En la vista de «todas las fuentes», una **insignia** en cada póster indica de dónde procede la película.
- **Género**, **Año**.
- **País** e **Idioma**: según la ficha de TMDB (o del servidor Emby, Jellyfin o Plex).
- **Calidad**: **4K** (2160p, UHD), **HD** (1080p, 720p, Blu-ray, WEB-DL…) u otra, según el nombre del archivo.
- **Estado**: **No visto**, **En curso**, **Visto** o **Favoritos**.
- **Orden**: título, añadidos recientemente, año, **nota de TMDB** o **duración**.

Las notas, duraciones, países e idiomas de los archivos de sus carpetas proceden de TMDB (se necesita una [clave TMDB](help:tmdb)): aparecen a medida que se buscan las fichas, lo que tarda unos minutos la primera vez. Una película sin nota queda al final al ordenar por nota.

## Disposición de la ventana y barra lateral {#colonnes}

![Disposición de la ventana y barra lateral](img:layout)

<!--mac-->
En la interfaz Clásica, la ventana tiene tres columnas:

- **Barra lateral**: Inicio, En directo, Películas, Series, Favoritos, Recientes, Guía TV, y después las categorías de la sección elegida y el estado de sus fuentes.
- **Lista**: los elementos de la sección o categoría, con el programa actual para los canales. El campo **Buscar** filtra la lista sin distinguir mayúsculas ni acentos.
- **Reproductor**: el vídeo, con el programa actual, su progreso y los próximos programas debajo.

Al hacer clic con el botón derecho en un elemento puede añadirlo a favoritos o copiar la dirección de la emisión.
<!--/mac-->

<!--pc-->
Selector En directo / Películas / Series, y después: todos los canales o películas, **Favoritos**, **Recientes**, y para la televisión en directo **Temas**, **Guía TV** y **MultiVista**; **Grabaciones**; las **categorías**. Abajo: la grabación y la descarga en curso (progreso, tiempo restante) y **Ajustes**.
<!--/pc-->

## Tres interfaces a elegir {#interfaces}

<!--mac-->
Kastideo ofrece tres presentaciones, que se eligen **por separado para el directo, las películas, las series y los favoritos / recientes**:

- **Clásica**: las tres columnas descritas en [Disposición de la ventana y barra lateral](help:colonnes).
- **TV** (solo directo): consulte [La interfaz TV](help:interface-tv).
- **Cine**: un gran **banner «destacado»** que se desplaza (consulte [El banner «destacado»](help:bandeau)) y después **filas horizontales**: continuar viendo, favoritos y una fila por categoría. Las películas y series aparecen como pósteres, los canales como miniaturas con el programa actual. Un clic en un canal abre el reproductor a pantalla completa. Un clic en el póster de una **película** o **serie** abre primero su **página de detalles**: imagen de fondo, póster, año, duración, géneros, nota, sinopsis, director, reparto (con fotos), un botón **Volver a Películas** (o Series) arriba a la izquierda, **Reproducir** / **Reanudar**, **Ver episodios**, **Tráiler**, **Descargar** y los botones de favoritos. La información procede de su proveedor IPTV; añada una clave **TMDB** gratuita (Ajustes > General > Fichas de películas y series) para obtener páginas más completas. **Volver** (o Esc) regresa al catálogo. En la parte superior de la ventana, las pestañas **En directo / Películas / Series / Guía / Favoritos / Recientes / Grabaciones** sustituyen a la barra lateral; la búsqueda funciona como en la interfaz Clásica. «Ver todo» abre una categoría completa como cuadrícula.

Para cambiar de interfaz:

- el botón **Interfaz** de la barra de herramientas (se aplica al tipo de contenido mostrado),
- el menú **Visualización**: **⌥⌘1** Clásica, **⌥⌘2** Cine, **⌥⌘3** TV (directo),
- o **Ajustes > Apariencia**.

Por ejemplo: TV para el directo y Cine para películas y series. La sección **Grabaciones** se muestra siempre en la interfaz Clásica. Por defecto es Clásica en todas partes.
<!--/mac-->

<!--pc-->
Ajustes > Apariencia > **Interfaz por tipo de contenido**:

- **Clásica**: tres columnas (barra lateral, lista con el programa actual, reproductor o detalles a la derecha).
- **Cine**: banner destacado, pósteres o miniaturas en filas horizontales, detalles a página completa. Para la televisión en directo: filas «Deporte ahora mismo», «Noticias en directo», «Esta noche» por tema, favoritos, recientes, categorías; un clic abre el canal a pantalla completa, **Volver** (o Esc) lo detiene.
- **TV** (solo directo): el canal a pantalla completa, como un televisor (consulte [La interfaz TV](help:interface-tv)).
<!--/pc-->

## El banner «destacado» (Cine) {#bandeau}

<!--mac-->
En la parte superior de Películas y Series, un **carrusel a todo el ancho** recorre una selección: imagen de fondo, póster, título, año, duración, géneros, nota, sinopsis y botones **Reproducir** (o **Reanudar** / **Ver episodios**), **Más información** (la página de detalles) y **Tráiler**. Mezcla:

- las **tendencias de TMDB** de esta semana que se encuentran en su catálogo (se necesita una clave TMDB);
- las **últimas novedades** de su proveedor;
- una **selección de una categoría** de su elección (por ejemplo «Estrenos» o «Netflix»), o de todo el catálogo al azar.

El desplazamiento se detiene mientras el ratón está sobre el banner; las flechas y los puntos permiten navegar. En **En directo**, el banner muestra **lo que se emite ahora** en sus canales favoritos y recientes, con el progreso, el siguiente programa y **Ver**.

Ajustes > Apariencia > **Banner «destacado»**: mostrar u ocultar, altura (compacto, normal, grande), velocidad de desplazamiento, fuentes del carrusel y categorías de películas y series.
<!--/mac-->

<!--pc-->
Recorre películas o series (tendencias de TMDB de esta semana disponibles para usted, últimas novedades, una selección de categoría) o, para la televisión en directo, el programa actual de sus canales. Flechas al pasar el ratón; se detiene mientras el ratón está encima. Ajustes > Apariencia > **Banner destacado**: mostrar u ocultar, altura, velocidad, fuentes.
<!--/pc-->

## Países e idiomas (Cine) {#pays}

<!--mac-->
Los proveedores suelen mezclar varios países (categorías «FR| …», «|PT| …», «ITALIA»…). Ajustes > Apariencia > **Países e idiomas (interfaz Cine)** enumera los países encontrados en los nombres de sus categorías, con el número de elementos: marque los que desea ver. Las **últimas novedades**, las **tendencias**, el **banner destacado** y las **filas de categorías** de la interfaz Cine solo muestran entonces esos países. **Conservar las categorías sin país** mantiene categorías como «Acción» o «Novedades». **Todos los países** vuelve a la visualización completa. Las listas Clásicas y la búsqueda siguen siendo completas.
<!--/mac-->

<!--pc-->
Los proveedores suelen mezclar varios países (categorías «FR| …», «|PT| …», «ITALIA»…). Ajustes > Apariencia > **Países e idiomas (interfaz Cine)** enumera los países encontrados en los nombres de sus categorías, con el número de elementos: elija los que quiere mostrar. Las **últimas novedades**, las **tendencias**, el **banner destacado** y las **filas de categorías** de la interfaz Cine solo muestran entonces esos países. **Conservar las categorías sin país** mantiene categorías como «Acción» o «Novedades». **Todos** vuelve a la visualización completa. Las listas y la búsqueda siguen siendo completas.
<!--/pc-->

## La interfaz TV (directo) {#interface-tv}

<!--mac-->
El canal ocupa todo el cuadro, como en un televisor. La primera vez que aparece, Kastideo reanuda el último canal que vio.

- **Panel de canales**: tecla **←**, **Retorno**, o mueva el ratón al borde izquierdo. Enumera los canales con número, logotipo, programa actual y progreso. El menú de la parte superior filtra por **Todos / Favoritos / Recientes / categoría**, y el campo **Buscar** filtra por nombre. Se cierra solo tras unos segundos (**→** o **Esc** para cerrarlo de inmediato).
- **Zapping**: **↑ / ↓** canal anterior / siguiente de la lista mostrada, **B** volver al canal anterior.
- **Número de canal**: escriba las cifras (por ejemplo **1** y después **2**); el canal se abre a los 1,6 s o con **Retorno**. Si su proveedor no numera los canales, el número se refiere a la posición en la lista mostrada.
- **Banner de información**: se muestra durante cinco segundos en cada cambio de canal (logotipo, número, programa actual, horarios, programa siguiente, hora). **I** o **→** lo muestra u oculta.
- Otras teclas: **F** favorito, **M** silencio, **Espacio** pausa (directo en diferido).
- Doble clic en la imagen o **⌘↩**: pantalla completa; la barra de herramientas se oculta.
- Las teclas del teclado no funcionan mientras se escribe en el campo de búsqueda. Las pestañas de la parte superior de la ventana permiten pasar a Películas, Series, etc.
<!--/mac-->

<!--pc-->
- **↑ / ↓**: canal anterior / siguiente; **escriba un número** (hasta 4 cifras).
- **←** o borde izquierdo: **panel de canales** (filtro, búsqueda, programa actual).
- **→** o **I**: **banner de información** (programa actual y siguiente).
- **B**: canal anterior — **F**: favorito — **M**: sonido — **Espacio**: pausa — **G**: guía de TV — **H**: inicio.
<!--/pc-->

## La guía de TV en cuadrícula {#guide-grille}

<!--pc-->
Ajustes > General > Página de inicio > **Al abrir la guía**: **Ahora** (hora actual) o **Última posición** (la hora y la categoría de su última visita). En la ficha de una serie, **Visto / no visto** marca una temporada o toda la serie.
<!--/pc-->

<!--mac-->
La sección **Guía TV** (barra lateral, pestaña **Guía TV** de las interfaces Cine y TV, **⌘7**, o la tecla **G** en la interfaz TV). Los canales están en filas, las horas en columnas; la línea roja marca la hora actual.

- **‹ ›** desplazan la cuadrícula, **Ahora** vuelve a la hora actual, el menú de fecha salta a otro día (19:00 para los días siguientes).
- Elija el intervalo de tiempo mostrado (**2 h / 3 h / 6 h**), filtre por **favoritos**, **recientes** o **categoría**, o busque un canal.
- Haga clic en un programa: descripción, botón **Ver**, **Grabar** (programa en curso) o **Programar grabación** (programa próximo). Un punto rojo marca una grabación programada.
- Los días pasados (menú de fecha, sección **Volver a ver**) y los programas marcados con ↺ permiten el **replay** (consulte [Replay](help:replay)).
- Haga clic en el nombre de un canal para verlo. Solo se enumeran los canales que tienen programas: si la cuadrícula está vacía, compruebe la dirección de la guía en los ajustes de la fuente.
<!--/mac-->

<!--pc-->
Inicio, barra lateral del directo, **Ctrl+7** o la tecla G en la interfaz TV. Canales en filas, horas en columnas, una línea roja en la hora actual; **‹ Ahora ›**, selector de día, intervalo de 2 h / 3 h / 6 h, filtro (todos, favoritos, recientes, tema, categoría) y búsqueda. Un clic en un programa abre sus detalles: **Ver**, **Grabar**, **Programar grabación** (punto rojo en la cuadrícula) o **Avisarme cuando empiece** (campana). En un programa pasado de un canal con replay (↺): **Volver a ver** o **Guardar este replay**; los días pasados están en el menú de fecha.
<!--/pc-->

## La televisión en directo por temas {#direct-theme}

<!--mac-->
La sección **Temas** de la barra lateral (bajo En directo) clasifica la televisión en directo por **tema** — Deportes, Auto y Moto (motor), Películas, Series, Noticias, Documentales, Naturaleza / Caza y Pesca, Infantil, Entretenimiento, Cocina y Hogar, Música, Generalista, Regional (regiones de France 3, televisiones locales), Internacional (canales extranjeros), Religión, Radio — sin las categorías que haya ocultado. Tres modos:

- **Ahora**: lo que se emite ahora, clasificado según el **género del programa** en la guía de TV (una película en un canal generalista aparece en «Películas»), con el progreso. Los canales **sin datos de guía** también se enumeran cuando su **nombre basta para clasificarlos** (beIN Sports → Deporte…): muestran su nombre, sin progreso.
- **Esta noche**: programas que empiezan **entre las 20:00 y las 23:00**. Clic derecho en un programa próximo > **Avisarme cuando empiece**.
- **Canales**: canales clasificados por especialidad. El tema se deduce automáticamente del nombre del canal (beIN, Eurosport → Deportes; BFM, LCI → Noticias…) y después de sus programas habituales; clic derecho > **Tema del canal** para corregirlo.

Cada canal aparece **una sola vez**, aunque su proveedor lo ofrezca en varias versiones (4K, FHD, HD, SD): Kastideo elige la versión adecuada a **su conexión** (ajuste **Automático** en Ajustes > General > Reproducción > Versión del canal): baja de versión tras una reproducción inestable y vuelve a subir tras tres reproducciones fluidas. Clic derecho > **Versión** para elegir otra.

Los temas se ofrecen también en otros lugares: filas «Deportes ahora», «Películas ahora»… en la parte superior de En directo en la interfaz **Cine**, un filtro **Temas** en el panel de canales de la interfaz **TV** y en la **Guía TV**, y etiquetas «Ahora en TV» (y «Esta noche») en la pantalla de **Inicio**.

En **Deportes**, una segunda fila filtra por **disciplina**: Fútbol, Rugby, Tenis, Baloncesto, Deportes de combate, Golf, Ciclismo, Balonmano, Motor, Deportes de invierno, Hípica, Atletismo y natación (a partir de los títulos, géneros y descripciones de los programas).

**Contenido para adultos**: los canales y contenidos cuyo nombre contiene «|XX|» (o que están en una categoría para adultos) se **ocultan en todas partes** por defecto. Para mostrarlos, junto con el tema **Adultos**: Ajustes > General > Reproducción > **Mostrar contenido para adultos**.

**Alertas de programas** (botón 🔔 de la vista Temas): Kastideo le avisa dos minutos antes de que empiece un programa cuyo título contenga una palabra elegida («PSG», «Fórmula 1»…), de un tema en sus canales favoritos, o un programa concreto. Aparecen una notificación y un banner **Ver**.
<!--/mac-->

<!--pc-->
Barra lateral > **Temas**: **Ahora mismo**, **Esta noche** (20:00–23:00) o **Canales**, filtrados por tema (Deportes, Noticias, Películas, Infantil, Documentales…) y, para el deporte, por disciplina. Una versión por canal (FHD, HD o SD según su conexión). Clic derecho: versión del canal, **tema del canal** (para corregir la clasificación), favoritos, editar el canal.
<!--/pc-->

# Reproducción

## Lo esencial {#lecture}

<!--pc-->
En **Windows, Linux y Android**, el menú **⋯** de la barra del reproductor ofrece la **velocidad** (películas, episodios), las **pistas de audio**, los **subtítulos** y el **formato de la imagen** (ajustar, llenar la pantalla, 16:9, 4:3). En directo, **◀◀ / ▶▶** cambian al canal anterior o siguiente de la categoría, y la barra muestra el **programa en curso** con su progreso y el siguiente. En un episodio aparecen **Siguiente** y **Episodios…**, y el siguiente episodio empieza solo al terminar (se puede desactivar en Ajustes > General > Reproducción).
<!--/pc-->

<!--mac-->
Kastideo reproduce todos los contenidos con el motor **VLC**: MPEG-TS (.ts) en directo, HLS (.m3u8), MP4, MKV, AVI…

- La reproducción empieza en cuanto selecciona un canal, una película o un episodio.
- Durante la apertura se muestran el logotipo y el nombre del canal. La insignia **«Listo en x s»** muestra después el tiempo de arranque (se puede desactivar en los ajustes).
- Los controles aparecen al pasar el ratón sobre el vídeo: reproducir / pausa, retroceder 10 s y avanzar 30 s para películas y episodios, barra de progreso, volumen (hasta el 200 %) y modo cine.
- Un clic en el vídeo lo pausa; un **doble clic** activa el **modo cine**: la ventana pasa a pantalla completa y solo queda visible el **vídeo** (sin columnas ni barra de herramientas; el botón verde de la ventana y **⌃⌘F** hacen lo mismo durante la reproducción). **Esc** o **⌘↩** para salir.
- **Reanudar la reproducción**: para películas y episodios, Kastideo recuerda su posición. Cuando vuelve a abrir uno, la reproducción se reanuda donde la dejó, con un mensaje que ofrece **empezar de nuevo**. Aparecen barras de progreso en las listas, pósteres y episodios. Se puede desactivar, y las posiciones se pueden borrar, en los ajustes.
- Para las fuentes Xtream, el directo se reproduce en formato MPEG-TS (.ts), como el reproductor de referencia de Xtream; si la emisión falla, Kastideo prueba automáticamente la variante .m3u8 (y viceversa).
<!--/mac-->

<!--pc-->
El reproductor (motor mpv) tiene una barra de control que se oculta sola, un punto de estado de la emisión, volumen, modo cine (doble clic o Ctrl+Intro) y pantalla completa (F11). Para películas y episodios: minilínea de tiempo, −10 s / +30 s, **reanudar** donde lo dejó, **Volver a los detalles**.
<!--/pc-->

## Barra de control, línea de tiempo y panel de información {#barre-controle}

<!--mac-->
- **Barra que se oculta sola**: aparece al mínimo movimiento del ratón y se oculta, junto con el puntero, tras 3 segundos de inactividad (permanece mientras el ratón está encima, en pausa o cuando el panel está abierto).
- **Detener** (botón ■ junto a reproducir / pausa, o **⌘.**): detiene la emisión. La zona de vídeo muestra «Ninguna reproducción» con un botón **Reiniciar**; la posición de una película o episodio se recuerda para reanudarla. Durante una emisión con Cast, detener también finaliza el Cast y el televisor vuelve a su programa. Si el canal se está grabando, Kastideo pide confirmación (la grabación se detiene con la reproducción).
- **Minilínea de tiempo** (películas y episodios): una línea fina sobre los botones que se engrosa al pasar el ratón y muestra el tiempo de destino; haga clic o arrastre para moverse.
- **Estado de la emisión**: un punto **verde** (Excelente), **naranja** (Aceptable) o **rojo** (Inestable) indica la calidad de la recepción, con la definición (SD, HD, 4K). Al pasar el ratón: resolución exacta, tasa de bits, fotogramas por segundo, imágenes perdidas e interrupciones en el último minuto.
- **Panel de información** (botón ⓘ o **⌘I**, Esc para cerrarlo): se desliza desde la derecha sobre el vídeo y muestra el canal con sus programas actual y siguientes, o la sinopsis y el reparto de una película; la elección de **pista de audio** (idioma, audiodescripción…) y de **subtítulos**; la calidad de recepción detallada.
<!--/mac-->

## MultiVista (varios canales a la vez) {#multivue}

<!--mac-->
**MultiVista** muestra hasta **4 canales en directo** en una ventana (1 a pantalla completa, 2 lado a lado, 3 o 4 en cuadrícula). **El sonido sigue al mosaico activo** (borde naranja): haga clic en un mosaico o use las teclas **1 a 4**.

- Ábrala: **Reproducción > MultiVista…** (**⌥⌘M**), o clic derecho en un canal > **Añadir a MultiVista**.
- En la ventana: **+** añade un canal (favoritos, recientes o búsqueda); al pasar el ratón por un mosaico, ⟳ cambia el canal y ✕ lo quita; **Detener todo** detiene todas las emisiones. Al cerrar la ventana se detiene MultiVista.
- Cada emisión utiliza **una conexión** con su proveedor, por lo que MultiVista está **desactivada por defecto**: introduzca el número de conexiones simultáneas de su suscripción en **Ajustes > General > Reproducción** (de 2 a 4) para activarla. El botón **Probar la conexión** de una fuente Xtream muestra este número. Al abrirla, la reproducción principal se detiene para liberar su conexión (salvo si graba); una grabación o una descarga también utiliza una conexión.
<!--/mac-->

<!--pc-->
**MultiVista** muestra hasta **4 canales en directo** en una pantalla. **El sonido sigue al mosaico activo** (borde naranja).

- **Activación**: cada canal utiliza una conexión con su proveedor, por lo que MultiVista permanece desactivada hasta que indique el número de **conexiones simultáneas** de su suscripción: Ajustes > General > Reproducción (de 2 a 4). **Detectar** consulta sus fuentes Xtream.
- **Apertura**: inicio > **MultiVista**, barra lateral del directo > **MultiVista**, **Ctrl+Alt+M**, o clic derecho en un canal > **Añadir a MultiVista**. El canal que estaba viendo pasa a ser el primer mosaico; si se está grabando, sigue grabando en segundo plano, sin sonido.
- **Añadir**: botón **+** (o tecla **A**): favoritos, recientes, todos los canales o búsqueda. Una celda vacía de la cuadrícula también ofrece «Añadir un canal».
- **Disposiciones** (arriba a la derecha): **Automática** (1 a pantalla completa, 2 lado a lado, 3 o 4 en cuadrícula), **Cuadrícula 2 × 2**, **Uno grande** y los demás pequeños, **Lado a lado**. La disposición se recuerda.
- **Vista grande ↔ mosaico**: **doble clic** en un mosaico (o pulse **G**) para agrandarlo con sonido; haga doble clic de nuevo en la vista grande para volver a la cuadrícula.
- **Al pasar el ratón por un mosaico**: agrandar, cambiar de canal, quitar. El nombre del canal y el programa actual se muestran en la parte inferior.
- **Grupos guardados** (icono de marcador): **Guardar este grupo…** almacena los canales y la disposición con un nombre (p. ej. «Multiplex de fútbol»); haga clic en un grupo para reabrirlo, la cruz lo elimina.
- **Teclado**: **1 a 4** sonido en ese mosaico, **G** agrandar, **A** añadir, **M** silencio, **Supr** quitar el mosaico activo, **F** o **F11** pantalla completa, **Esc** salir de la pantalla completa y después de MultiVista.
- **Detener todo** (o Volver) detiene todas las emisiones y vuelve a la pantalla anterior.

> Una grabación o una descarga también utilizan una conexión: un icono ⓘ se lo recuerda en la barra de MultiVista. Si un mosaico indica «El canal no responde», es probable que el proveedor rechace una conexión adicional: quite un canal o reduzca el número de conexiones.
<!--/pc-->

## Varias fuentes de directo: MultiVista e imagen en imagen {#multivue-sources}

Si tiene **varias fuentes de directo** (dos suscripciones IPTV, o una suscripción y una lista de canales públicos), [MultiVista](help:multivue) las **mezcla**. Hay tres pasos.

**1. Conexiones de cada suscripción.** En **Ajustes > General > Reproducción**, una línea por suscripción (nombre + identificador de cuenta, para distinguir dos cuentas del mismo proveedor) establece el número de emisiones simultáneas que permite: 1 en la mayoría de las suscripciones, 4 en una lista pública. En Windows, Linux y Android, **Detectar** consulta las cuentas Xtream.

**2. Número de pantallas.** En la ventana de MultiVista, indique el número de **pantallas** (de 1 a 4, como máximo la suma de las conexiones de sus fuentes).

**3. Fuente de cada pantalla.** Cada pantalla está **reservada a una fuente**: la insignia de la parte superior de la pantalla permite cambiarla. El selector de canales de esa pantalla solo ofrece canales de su fuente, y una fuente no puede reservar más pantallas que conexiones tiene.

**Disposición**: lado a lado, apiladas, cuadrícula, o **una grande + miniaturas (PIP)** (menú de disposición de MultiVista). En esta última, un canal llena el cuadro y los demás flotan como **pequeñas miniaturas 16:9**: **arrastre** una miniatura para moverla (se ajusta a la esquina más cercana), haga **doble clic** en ella para intercambiarla con la grande (el sonido la sigue) y ajuste su **tamaño** (pequeño, mediano, grande) en la barra de MultiVista. Un solo clic da el sonido a una miniatura.

**Elegir un canal.** El selector refleja la interfaz Clásica: a la izquierda **Favoritos**, **Recientes** y las **categorías de la fuente de la pantalla** (en su orden, con las categorías ocultas o renombradas de «Gestionar las categorías»), a la derecha los canales con su programa actual. Un **clic** reproduce el canal en la pantalla y mantiene abierto el selector para hacer zapping; un **doble clic** lo reproduce y lo cierra. Un canal que ya se muestra en otra pantalla aparece atenuado. La búsqueda abarca todas las categorías de la fuente.

**¿Dónde encuentro MultiVista?** En Mac: la entrada **MultiVista** de la barra lateral, el botón de la barra de herramientas, el botón **MultiVista** de la pantalla de Inicio (junto a Favoritos y Grabaciones), el botón de la barra del reproductor (abre MultiVista con el canal que está viendo), el menú Reproducción y ⌥⌘M. En Windows, Linux y Android: Inicio, la barra lateral de En directo, el botón de la barra del reproductor y Ctrl+Alt+M.

**Imagen en imagen (PIP).** Mientras se reproduce un canal en directo, el botón de **imagen en imagen** (arriba a la derecha del reproductor) abre un **segundo canal en una ventana pequeña** en una esquina, sin sonido. **Haga clic en la ventana pequeña** para intercambiarla con el canal principal, o en la cruz para cerrarla. El segundo canal debe proceder de una fuente con una conexión libre: con una única suscripción limitada a una conexión, elija un canal de la lista pública (o de una segunda suscripción). La ventana pequeña se cierra al salir del reproductor.

## Si un canal no arranca {#chaine-ne-demarre-pas}

<!--mac-->
Si no llega ninguna imagen tras **20 segundos**, Kastideo prueba automáticamente el otro formato de emisión (.ts o .m3u8) y después muestra un mensaje de error con los detalles devueltos por el motor VLC.

El **Registro** (menú **Reproducción > Registro de reproducción…**, **⌥⌘L**, o el botón del mensaje de error) es la herramienta de diagnóstico de Kastideo. Los nombres de usuario y las contraseñas están **ocultos** en él: puede copiarlo para compartirlo si tiene un problema.

- **Temas**: los mensajes se clasifican en *Guía TV*, *Reproducción y relé*, *Fuentes y catálogos*, *Grabaciones*, *Fichas TMDB*, *Actualizaciones* y *Pantalla y otros*. Haga clic en uno o varios temas para ver solo esos (se indica el número de líneas de cada tema).
- **Busque** una palabra en el registro, o muestre solo los **errores y advertencias**.
- **Copiar lo mostrado** copia solo lo que se muestra (temas, búsqueda), con el filtro indicado en la parte superior.
- **Nivel de detalle** (por tema): *Normal* (lo esencial), *Detallado* (por defecto para la Guía TV) o *Depuración* (todo). El ajuste se aplica a las líneas escritas a partir de ese momento; los errores y advertencias se conservan siempre.
- **Sesión actual / Sesión anterior**: el registro se conserva en el disco, de modo que puede leer lo ocurrido al iniciar en la sesión anterior. **Mostrar la carpeta del registro** revela el archivo en el Finder.
<!--/mac-->

## Directo en diferido {#differe}

<!--mac-->
Ponga en **pausa** un canal en directo: el motor VLC sigue recibiendo la emisión y la almacena. Al reanudar, está viendo en **diferido** (indicador amarillo «DIFERIDO −2:34» en los controles). Si una emisión no se puede pausar, el botón aparece atenuado.

En diferido, los controles ofrecen:

- una **línea de tiempo**: el punto de pausa a la izquierda, el **directo** a la derecha. **Arrastre el cursor hacia la derecha** para avanzar: Kastideo acelera la reproducción hasta el punto elegido (marcador amarillo) y después vuelve a la velocidad normal;
- **+30 s** (o ⌘]): avanza 30 segundos del mismo modo;
- la **velocidad** (×1, ×1,25, ×1,5, ×2): acelere para reducir el retraso; la reproducción vuelve a ×1 sola cuando alcanza el directo;
- **Ponerse al día**: acelera hasta el directo, sin saltarse nada;
- **Volver al directo**: vuelve al directo inmediatamente. Como el motor VLC normalmente no puede saltar dentro del búfer de diferido, la emisión se vuelve a abrir y el búfer se borra. Si la emisión permite desplazarse, el búfer se conserva y −10 s / +30 s saltan directamente.

**¿Dónde se almacena el diferido?** En la carpeta temporal de Kastideo (`~/Library/Containers/fr.jmezes.kastideo/Data/tmp/`, archivos `vlc-timeshift-…`), que se borra al cambiar de canal; cuente de 1 a 4 GB por hora según la calidad. Ajustes > General > Reproducción: **Duración máxima del diferido** (de 30 min a 3 h, o ilimitada; al alcanzarla, la reproducción se reanuda sola), **Velocidad de puesta al día** y un botón **Mostrar** para abrir la carpeta.
<!--/mac-->

<!--pc-->
Ponga un canal en pausa (o retroceda con ← o la barra): sigue almacenándose en búfer (hasta 1 h por defecto, ajustable). Sin ninguna acción por su parte, el canal permanece «EN DIRECTO». La barra de diferido muestra el retraso, un control deslizante para retroceder o ponerse al día más rápido, la velocidad, **Ponerse al día** y **Volver al directo**. ← / →: −10 s / +30 s.
<!--/pc-->

## Replay: ver un programa que ya se emitió {#replay}

<!--mac-->
Algunas suscripciones IPTV conservan los canales hasta **14 días** (según el proveedor y el canal). Kastideo lo detecta por sí mismo: los canales con replay muestran un icono **↺** en las listas y en la Guía TV.

- **En la Guía TV**: haga clic en un programa **pasado** (marcado con ↺) y después en **Volver a ver**. En el programa **actual**, **Ver desde el principio** lo reproduce desde el comienzo. **Guardar este replay** descarga el programa del archivo del proveedor (carpeta de grabaciones).
- **Días anteriores**: el menú de fecha de la Guía TV ofrece **Volver a ver (replay)** con los días pasados.
- **Desde un canal**: clic derecho en el canal > **Volver a ver (replay)** (programas recientes de ese canal). La interfaz Cine también tiene una fila **Para volver a ver** (sus canales favoritos con replay).
- **Durante un replay**, la barra del reproductor permite pausar y moverse por el programa. Al final, Kastideo **vuelve a la emisión en directo del canal** (se puede desactivar).
- **Ajustes > General > Replay**: activar o desactivar el replay, número de **días de programas pasados conservados en la guía** (más días = más memoria), **desfase horario** (si el programa reproducido está desplazado unos minutos o una hora, corríjalo aquí; la zona horaria del servidor se lee automáticamente), vuelta al directo.
- Un replay cuenta como **una conexión**: cierra el canal actual, igual que al cambiar de canal.
- Si un replay no arranca, abra el **Registro** (tema «Reproducción y relé»): allí figuran la dirección de archivo construida y el desfase utilizado. La guía del proveedor debe contener programas pasados: recárguela después de aumentar el número de días conservados.
<!--/mac-->

<!--pc-->
Algunas suscripciones IPTV conservan los canales hasta **14 días** (según el proveedor y el canal). Kastideo lo detecta por sí mismo: los canales con replay muestran un icono **↺** en las listas y en la Guía TV.

- **En la Guía TV**: haga clic en un programa **pasado** (marcado con ↺) y después en **Volver a ver**. En el programa **actual**, **Ver desde el principio** lo reproduce desde el comienzo. **Guardar este replay** descarga el programa del archivo del proveedor (carpeta de grabaciones).
- **Días anteriores**: el menú de fecha de la Guía TV ofrece **Volver a ver (replay)** con los días pasados.
- **Desde un canal**: clic derecho en el canal > **Volver a ver (replay)…** (programas recientes de ese canal). La interfaz Cine también tiene una fila **Para volver a ver** (sus canales favoritos con replay).
- **Durante un replay**, la barra del reproductor permite pausar y moverse por el programa. Al final, Kastideo **vuelve a la emisión en directo del canal** (se puede desactivar).
- **Ajustes > General > Replay**: activar o desactivar el replay, número de **días de programas pasados conservados en la guía** (más días = más memoria), **desfase horario** (si el programa reproducido está desplazado unos minutos o una hora, corríjalo aquí; la zona horaria del servidor se lee automáticamente), vuelta al directo.
- Un replay cuenta como **una conexión**: cierra el canal actual, igual que al cambiar de canal.
- Si un replay no arranca, abra el **Registro** (botón Registro, tema «Reproducción y relé»): allí figuran la dirección de archivo construida y el desfase utilizado. La guía del proveedor debe contener programas pasados: recárguela después de aumentar el número de días conservados.
<!--/pc-->

## Una sola conexión a la vez {#connexion-unique}

<!--mac-->
La mayoría de las suscripciones IPTV permiten solo **una emisión simultánea**. Kastideo cierra siempre la emisión actual antes de abrir la siguiente: puede hacer zapping sin riesgo de superar su límite. Si la reproducción falla, compruebe que ningún otro dispositivo (televisor, teléfono, Piboard…) esté viendo con la misma suscripción.
<!--/mac-->

<!--pc-->
La mayoría de las suscripciones permiten una sola conexión. Kastideo cierra el canal anterior antes de abrir el siguiente (**relé de emisión**, Ajustes > General > Reproducción) y pregunta antes de interrumpir una grabación.
<!--/pc-->

## Enviar a un televisor (Cast) {#cast}

Envíe lo que está viendo —**un canal en directo, una película, una serie, un vídeo local o YouTube**— a un televisor de la misma red, sin salir de Kastideo. La barra de reproducción sigue siendo su mando a distancia.

### Qué es posible

- **Chromecast, Google TV, Android TV** (y muchos televisores con Chromecast integrado): toda la reproducción pasa al televisor.
- **Apple TV (AirPlay)**: Kastideo no puede enviar el vídeo directamente. Use la **duplicación de pantalla** de macOS (véase más abajo).
- **YouTube**: el vídeo se abre en la aplicación YouTube del televisor, o en el navegador (a su elección en los Ajustes).

### Enviar algo

1. Inicie un canal, una película, una serie o un vídeo.
2. En la barra de reproducción, haga clic en el botón **TV**.
3. Elija el dispositivo de la lista. Si no aparece nada, haga clic en **Buscar de nuevo**: el televisor debe estar encendido y en la misma red.
4. La imagen pasa al televisor. En el ordenador aparece una pantalla con «Enviando a…».

La reproducción **se reanuda donde estaba**. Pausa, reproducción, salto de 10 / 30 s, posición, volumen y silencio de la barra actúan sobre el televisor. Si inicia otro elemento durante el envío, también se envía al televisor.

Para volver, elija **Detener el envío** (o **Reanudar en el ordenador**): la reproducción se reanuda en el ordenador en la misma posición.

<!--pc-->
### ffmpeg: conversión del vídeo

En Windows y Linux, Kastideo prepara el vídeo con **ffmpeg** antes de enviarlo al televisor. Se incluye con la versión de Windows y con el AppImage de Linux. Con el paquete .deb, instálelo: `sudo apt install ffmpeg`. Si Kastideo no lo encuentra, indique su ruta en **Ajustes > General > Cast**.

- **Preparación del vídeo**: *Automática* copia el vídeo cuando ya es H.264 (ligera para el ordenador) y lo convierte en caso contrario; *Convertir siempre* es la más compatible.
- **Resolución máxima**: 720p o 1080p.
- **Añadir un televisor por su dirección IP**: útil si la búsqueda automática no lo ve (wifi de invitados, VLAN…).

El Cortafuegos de Windows puede pedir que se permita Kastideo: acepte en las redes **privadas**; de lo contrario, el televisor no puede leer la emisión.
<!--/pc-->
<!--mac-->
### Apple TV y AirPlay

VLC, el motor de reproducción de Kastideo, no envía vídeo por AirPlay. Para un Apple TV: **Centro de control > Duplicar pantalla** (o **Ajustes del Sistema > Pantallas**), elija el Apple TV y reproduzca Kastideo a pantalla completa. El botón TV de la barra ofrece un acceso directo a los ajustes de pantalla.

### Permiso de red

En el primer uso, macOS pregunta si Kastideo puede **encontrar dispositivos en la red local**: acepte; de lo contrario no aparecerá ningún televisor (Ajustes del Sistema > Privacidad y seguridad > Red local > Kastideo). El menú del botón TV tiene un acceso directo a este ajuste. Si ya está permitido, elija **Buscar de nuevo** y compruebe que el Mac y el televisor están en la misma red (sin wifi de invitados, sin VPN).
<!--/mac-->

### YouTube en el televisor

En **Ajustes > General > Cast**, elija:

- **La aplicación YouTube del televisor**: Kastideo pide al televisor que abra YouTube en el vídeo elegido (clic derecho en un vídeo > **Reproducir en un televisor**). La aplicación YouTube debe estar instalada en el televisor.
- **Navegador (botón Cast de Chrome)**: el vídeo se abre en su navegador; use el botón **Enviar** de Chrome para enviarlo al televisor.

### Límites que conviene conocer

- Una sola conexión con su proveedor: durante el envío, el ordenador deja de reproducir el canal (consulte [Una sola conexión a la vez](help:connexion-unique)).
- No se puede saltar por el **directo** durante el envío; el **diferido** del ordenador se corta.
- La **grabación** de canales y **MultiVista** no se combinan con el envío.
- Hay unos segundos de retraso, más que con la reproducción local.
- Un televisor que no responde a la búsqueda: compruebe que está encendido y en la misma red wifi o Ethernet que el ordenador.

## Imagen congelada: decodificación por software {#image-figee}

Algunos canales muestran una imagen y después se quedan **congelados** mientras la emisión sigue llegando. La causa habitual es que el **decodificador por hardware** del ordenador (tarjeta gráfica o chip de vídeo) falla con esa emisión. La **decodificación por software** utiliza en su lugar el procesador: es más pesada, pero más tolerante.

### Recurso automático

Por defecto, cuando la imagen permanece congelada más de 6 segundos (o el decodificador por hardware notifica errores repetidos), Kastideo **vuelve a abrir el canal con decodificación por software** y lo recuerda: las siguientes reproducciones de ese canal usan software directamente. Se añade una línea explicativa al **Registro de reproducción** («Décodage : … réouverture en décodage logiciel»).

<!--pc-->
En Windows y Linux, la detección se basa en el número de imágenes mostradas por el motor y en sus mensajes de error del decodificador por hardware. Si un canal se congela sin ser detectado, active la decodificación por software manualmente (más abajo) y avísenos.
<!--/pc-->

### Manualmente

- **Para un canal**: clic derecho en el canal > **Decodificación por software (imagen congelada)**. El canal se vuelve a abrir de inmediato; repita para volver al decodificador por hardware.
- **Para todo**: <!--mac-->**Ajustes (⌘,) > General > Reproducción**<!--/mac--><!--pc-->**Ajustes (Ctrl+,) > General > Reproducción**<!--/pc--> > **Decodificar siempre por software**. Consume más energía y procesador, sobre todo en 4K.
- **Desactivar el recurso automático**: en el mismo lugar, **Decodificación por software automática cuando la imagen se congela**.
- **Olvidarlo todo**: el botón «Restablecer» (Mac) o «Olvidar los canales configurados con decodificación por software» (Windows/Linux) borra la lista recordada.

### Si no es suficiente

Un canal que sigue congelado incluso por software suele tener una emisión defectuosa en el proveedor: consulte el **Registro de reproducción** y pruebe otra versión del canal (HD, SD…).

## Búfer {#tampon}

<!--mac-->
En **Ajustes > General > Reproducción**, elija el equilibrio entre velocidad y estabilidad:

- **Rápido** (por defecto): 0,4 s de reserva, el zapping más corto.
- **Equilibrado**: 1 s.
- **Estable**: 3 s, para conexiones o servidores poco fiables (menos interrupciones, arranque más lento).
<!--/mac-->

## El Registro (diagnóstico) {#journal}

<!--pc-->
El **Registro** (**Ctrl+Alt+L**, o el botón de la pantalla de inicio y de los mensajes de error) es la herramienta de diagnóstico de Kastideo. Los nombres de usuario y las contraseñas están **ocultos** en él: puede copiarlo para compartirlo.

- **Temas**: *Guía TV*, *Reproducción y relé*, *Fuentes y catálogos*, *Grabaciones*, *Fichas TMDB*, *Actualizaciones*, *Pantalla y otros*. Haga clic en uno o varios temas para ver solo esos (se indica el número de líneas por tema).
- **Busque** una palabra, o muestre solo los **errores y advertencias**.
- **Copiar lo mostrado** copia solo lo que se muestra, con el filtro en la parte superior.
- **Nivel de detalle** (por tema): *Normal*, *Detallado* (por defecto para la Guía TV) o *Depuración* (todo). El ajuste se aplica a las líneas escritas a partir de ese momento; los errores y advertencias se conservan siempre.
- **Sesión actual / Sesión anterior**: el registro se conserva en el disco (la ruta de la carpeta se muestra en la parte inferior de la ventana), de modo que puede leer lo ocurrido al iniciar en la sesión anterior.
<!--/pc-->

# Grabaciones y descargas

## Visión general {#enregistrements}

<!--mac-->
Todo está en la sección **Grabaciones** de la barra lateral (**⌘6**): grabación en curso, conversiones, descargas, programaciones y archivos grabados (haga clic para verlos, clic derecho para mostrarlos en el Finder o eliminarlos).

Los archivos se guardan en **~/Movies/Kastideo** (se puede cambiar en **Ajustes > Grabaciones**) y se nombran automáticamente, por ejemplo «TF1 – Le goût du détail – 2026-10-18 20h50».

**Duración de la grabación.** La grabación **empieza de inmediato**, sin preguntar nada. Un banner «Grabación iniciada» permite entonces elegir cuándo detenerla: en 15 min, 30 min, 1 h, 2 h…, **a una hora concreta**, o **sin límite**. Si no elige nada, la grabación se detiene al **final del programa** (guía de TV, margen incluido) o, cuando la guía no lo conoce, tras la **duración por defecto** establecida en **Ajustes > Grabaciones** (2 h de entrada; «Sin límite» es posible). Puede cambiar la detención en cualquier momento con el botón **Duración** de la fila «Grabación en curso», que también muestra el tiempo restante.
<!--/mac-->

## Grabar en directo {#enregistrer}

<!--mac-->
- Mientras se reproduce un canal, haga clic en **●** en los controles, en **Grabar** bajo el vídeo, o use **⇧⌘R**. La insignia **REC** muestra la duración.
- La grabación se detiene automáticamente al final del programa en curso (según la guía de TV, más el margen posterior), o cuando hace clic en **■**.
- Usa **la misma conexión** que la reproducción: no se consume nada más de su suscripción.
- Clic derecho en un canal > **Grabar ahora**: si está viendo otro canal, Kastideo pregunta si debe detener la reproducción y después graba en segundo plano.
- Un **banner** en la parte inferior de la ventana confirma cuándo empieza y termina una grabación y muestra **la carpeta** donde está el archivo (botón **Mostrar**). Si la carpeta elegida en los ajustes ya no es accesible, el archivo se coloca en ~/Movies/Kastideo y el banner lo indica. Los pasos detallados figuran en el **Registro de reproducción**.
- **Durante la grabación**, el archivo es visible y crece en la subcarpeta **En curso** de la carpeta de grabaciones (una carpeta con el nombre del programa). Al detenerse, se mueve a la carpeta de grabaciones y se elimina la subcarpeta. Si el motor VLC no crea el archivo en 10 segundos, Kastideo lo reintenta automáticamente en una carpeta temporal (el archivo aparece entonces solo al detenerse); «Grabación imposible» solo se muestra tras ambos intentos, con detalles en el Registro de reproducción (⌥⌘L). La duración solo está limitada por el espacio en disco: cuente de 1 a 3 GB por hora según el canal (aparece una advertencia por debajo de 3 GB libres).
- Al final, la grabación se **convierte a MP4** sin pérdida de calidad (reproducible en QuickTime, en iPhone y en iPad). El archivo .ts aparece primero y se sustituye por el .mp4 cuando termina la conversión (unos minutos para 2 horas; se muestra en la sección Grabaciones). La imagen se copia sin pérdida; el **audio se convierte a AAC** (algunos canales emiten audio MP2 o AC-3 que QuickTime reproduce en silencio). Los subtítulos DVB y el teletexto, que MP4 no puede contener, se descartan; si la conversión falla, un segundo intento conserva solo la imagen y el audio principal y, como último recurso, se conserva el .ts. Esto se puede desactivar en los ajustes.
<!--/mac-->

<!--pc-->
Botón redondo rojo en la barra del reproductor, tecla **R**, o clic derecho en un canal > **Grabar ahora**: el canal se graba hasta el final del programa en curso (más el margen) o hasta que lo detenga, en **Vídeos/Kastideo/Enregistrements**.

- Los bytes de la emisión se copian tal cual a un archivo **.ts**, sin pérdida: el canal que se está viendo se copia desde el relé (sin segunda conexión con el proveedor); otro canal se descarga directamente, reconectando si la emisión se corta.
- Al final, el .ts se convierte sin pérdida a **MKV** (formato por defecto, Ajustes > Grabaciones); si la conversión falla, se conserva el .ts, que se reproduce en todas partes.
- Las emisiones HLS (.m3u8) y la reproducción sin relé siguen pasando por el motor de vídeo.
<!--/pc-->

## Programar una grabación {#programmer}

<!--mac-->
- En la guía de TV bajo el vídeo, **haga doble clic** en un programa próximo, o clic derecho > **Programar grabación**. Un punto rojo marca los programas programados.
- Clic derecho en un canal > **Programar una grabación…** (o el icono de calendario bajo el vídeo): elija un programa de la guía u horarios personalizados.
- Los **márgenes** anterior y posterior (2 y 5 minutos por defecto, ajustables) evitan perder el principio o el final.
- A la hora programada, la grabación empieza en segundo plano. Si está viendo otro canal, Kastideo pregunta si debe detener la reproducción; sin respuesta, la grabación empieza tras 60 segundos.
<!--/mac-->

<!--pc-->
- **Clic derecho en un canal en directo > Programar una grabación…**, o el botón **Programar…** de la pantalla Grabaciones (después elija el canal: favoritos, recientes o búsqueda).
  - **Programas de la guía**: los próximos programas del canal, con **Programar** (o **Grabar** para el actual). Una marca indica los ya programados.
  - **Franja horaria**: día, hora de inicio y de fin, título opcional, para un canal sin guía de TV o un programa concreto. Un final anterior al inicio termina al día siguiente.
  - **Repetición** (lista arriba a la derecha): **una vez**, **todos los días**, **de lunes a viernes** o **todas las semanas**. La siguiente repetición se añade automáticamente; el botón ⟲ de una grabación repetida en la lista deja de repetirla.
- Desde los detalles de un programa próximo (guía de TV, temas): **Programar grabación**.
- Se añaden los márgenes anterior y posterior (Ajustes > Grabaciones). Kastideo debe estar abierto a la hora programada: active **Iniciar Kastideo al iniciar sesión** si es necesario (Ajustes > General).
<!--/pc-->

## Descargar una película o episodios sin verlos {#telecharger}

<!--mac-->
- Clic derecho en una película o un episodio > **Descargar** o **Descargar esta noche**, o el botón **Descargar** bajo el vídeo.
- Para una serie: el botón **Descargar** de su página > la temporada mostrada o toda la serie.
- Las descargas se realizan **una tras otra** (cola). «Esta noche» empieza a las 2:00 por defecto (ajustable).
- Puede pausar, reanudar o cancelar cada descarga en la sección Grabaciones.
- **Indicador permanente**: mientras haya una descarga activa, un anillo de progreso permanece visible en la barra de herramientas. Un clic abre los detalles: progreso de la película o episodio actual, «episodio X de N», progreso de la serie o del lote, velocidad y **tiempo restante estimado** (que se afina a medida que avanza la descarga).
<!--/mac-->

<!--pc-->
Botón **Descargar** en los detalles de una película (ahora o **esta noche**), **Descargar la temporada** o el icono de cada episodio para una serie, clic derecho > Descargar. Una descarga a la vez, reanudada tras una interrupción, en pausa durante la reproducción (ajustable). Los archivos van a **Vídeos/Kastideo/Films** y **Séries/<serie>**.
<!--/pc-->

## Conexión única: ¿quién tiene prioridad? {#priorite}

<!--mac-->
Su suscripción permite una sola conexión. Por eso Kastideo hace una sola cosa a la vez y **le pregunta siempre** antes de interrumpir algo:

- Cambia de canal durante una grabación: Kastideo pregunta si debe **detener la grabación**.
- Inicia la reproducción durante una descarga: la descarga se **pausa** y se reanuda sola cuando la reproducción se detiene.
- Los archivos ya grabados se pueden ver en cualquier momento, incluso durante una grabación en segundo plano.
<!--/mac-->

## Pantalla de grabaciones {#ecran-enregistrements}

<!--pc-->
Grabación en curso (detener), descargas (pausar, reanudar, cancelar), grabaciones programadas e historial, archivos de la carpeta: un clic los reproduce, clic derecho para mostrarlos en la carpeta o eliminarlos.
<!--/pc-->

## Fichas en su idioma {#fiches-langue}

<!--pc-->
Con una **clave TMDB** (Ajustes > General), los títulos, sinopsis, géneros y episodios provienen de TMDB, en el idioma de la interfaz. Cuando la única sinopsis disponible es la del proveedor en otro idioma (portugués, español…), aparece plegada: **Mostrar la sinopsis (portugués)** la muestra de todos modos. No aparece en el banner ni en la lista de episodios.
<!--/pc-->

## Conviene saber {#bon-a-savoir}

<!--mac-->
- Kastideo debe **permanecer abierto** y el Mac **encendido** para las grabaciones programadas y las descargas nocturnas. Kastideo impide la suspensión automática durante la actividad y en la hora anterior, pero no el apagado ni la suspensión manuales.
- Una **notificación de macOS** avisa del inicio y el final de las grabaciones y descargas (se puede desactivar).
- **Limpieza automática** (opcional): las grabaciones anteriores al número de días elegido se mueven a la Papelera.
- Una alerta le avisa cuando queda poco espacio en disco.
- Los derechos de copia dependen de las condiciones de su proveedor: Kastideo graba para su uso privado lo que su suscripción ya le ofrece.
<!--/mac-->

## Limpiar la lista de grabaciones {#nettoyer-liste}

<!--mac-->
En la sección **Grabaciones** puede **quitar de la lista las grabaciones terminadas** (las programaciones, las descargas y la grabación en curso nunca se tocan).

- **Una grabación**: el botón de papelera de la fila, o clic derecho > **Quitar de la lista…**.
- **Varias**: el botón **Seleccionar**, marque las filas (o **Seleccionar todo**) y después **Quitar la selección**.
- **Todo**: el botón **Vaciar la lista…**.

Se abre entonces un cuadro de diálogo. Por defecto **solo se limpia la lista**: el archivo permanece en la carpeta de grabaciones y no volverá a aparecer en la lista. Marque **Eliminar también el archivo o archivos del almacenamiento** para borrarlo también (Papelera en Mac); se muestra entonces el espacio liberado. **Recordar esta elección** conserva su respuesta para la próxima vez.

Tras una simple retirada de la lista, un banner **Deshacer** permanece visible unos diez segundos.

Si un archivo ya no existe en el almacenamiento, o no se puede eliminar, la retirada continúa de todos modos: una notificación le avisa y, si hay varios avisos, una ventana los enumera.
<!--/mac-->

# Organizar y personalizar

## Corregir un canal {#corriger}

<!--mac-->
Algunos canales están mal referenciados por el proveedor (nombre erróneo, programas erróneos, logotipo ausente). Clic derecho en el canal > **Editar el canal…**:

- **Nombre** y **número** (usado para el zapping por número en la interfaz TV);
- **Logotipo**: una dirección de imagen, o **Elegir un archivo…** (la imagen se copia en Kastideo);
- **Programas de la guía de TV**: si los programas mostrados son erróneos o faltan, busque el canal correcto en la lista (guía del proveedor y guía de respaldo); el programa que se emite ahora ayuda a reconocerlo.

La corrección solo se aplica a **esta versión** del canal (FHD, HD, SD… se corrigen por separado) y sobrevive a las actualizaciones de las fuentes. **Restaurar el original** la deshace.
<!--/mac-->

<!--pc-->
Clic derecho en un canal > **Editar el canal…**: nombre, número, logotipo (dirección de imagen o un archivo copiado en Kastideo) y canal de la **guía de TV** (búsqueda entre las guías del proveedor y de respaldo). La corrección se aplica a esta versión del canal (HD, FHD…) y sobrevive a todas las actualizaciones. **Restaurar** vuelve al original.
<!--/pc-->

## Organizar las categorías {#categories}

<!--mac-->
No tiene que conformarse con la lista y el orden de categorías de su proveedor. Abra **Visualización > Gestionar las categorías…** (**⌥⌘C**), el botón junto al título «Categorías» de la barra lateral, o haga clic derecho en una categoría. Elija la sección (**Directo**, **Películas** o **Series**) y después:

- **Reordenar**: arrastre las categorías en la lista, o use el menú **…** > **Mover arriba del todo / abajo del todo**. **Ordenar A → Z** ordena todo alfabéticamente.
- **Seleccionar / deseleccionar todo**: la casilla sobre la lista marca o desmarca de una vez todas las categorías listadas. Con una búsqueda (por ejemplo «PT»), solo afecta a las categorías encontradas: práctico para ocultar un país entero de una vez y mostrar después solo las que desea.
- **Ocultar**: desmarque una categoría (o clic derecho > **Ocultar esta categoría** en la barra lateral). Una categoría oculta desaparece **en todas partes**: barra lateral, listas de Directo / Películas / Series, búsqueda, Guía TV, interfaces Cine y TV, banner destacado. Sus favoritos y recientes siguen disponibles.
- **Ocultar por palabra clave**: escriba por ejemplo «PAKISTAN» o «ARABIC»: se ocultan todas las categorías cuyo nombre la contenga, incluidas las que el proveedor añada más adelante. Haga clic en la cruz de una palabra clave para deshacerlo.
- **Renombrar**: el lápiz da un nombre más legible («FRANCE FHD | OTT» → «Francia HD»); **Nombre original** lo deshace.
- **Mostrar todo** vuelve a mostrar las categorías ocultas; **Restablecer…** vuelve por completo a la organización del proveedor.

Las categorías nuevas que añada el proveedor aparecen junto a su vecina original.
<!--/mac-->

<!--pc-->
- **Clic derecho en una categoría** de la barra lateral: **Renombrar…**, **Mover arriba del todo**, **Subir**, **Bajar**, **Mover abajo del todo**, **Ocultar esta categoría**, **Gestionar las categorías…**.
- **Ajustes > Categorías** (o el icono junto a «Categorías»): para TV en directo, películas o series; arrastre para reordenar, desmarque para ocultar en todas partes, doble clic para renombrar, **palabras clave** para ocultar de una vez todas las categorías que las contengan (p. ej. «PAKISTAN»), **Ordenar de A a Z**, **Restablecer**.
- **Seleccionar / deseleccionar todo**: la casilla sobre la lista marca o desmarca de una vez todas las categorías listadas. Con la **búsqueda** (p. ej. «PT»), solo afecta a las categorías encontradas: oculte un país entero en dos clics y marque después solo las que desea.

Una categoría oculta lo está en todas partes: listas, búsqueda, inicio, filas.
<!--/pc-->

## Corregir la ficha de una película o serie {#corriger-fiche}

Cuando el póster, el título o la sinopsis de una película o serie son erróneos (por ejemplo, dos películas comparten el mismo título), puede **vincularla a la ficha correcta de TMDB** o **introducir los datos usted mismo**. Funciona con **Mis vídeos** (carpetas, Jellyfin, Emby, Plex) y con las películas y series de la **suscripción IPTV**, en Mac, Windows, Linux y Android.

### Abrir la ventana

Clic derecho (o pulsación larga) en la película o serie y después **Corregir la ficha…**; el enlace también está al final de la página de detalles.

### Vincular a un código TMDB

1. En **themoviedb.org**, busque la película correcta. El **número** está en la dirección de la página: `themoviedb.org/movie/12345-hero` → **12345** (para una serie: `…/tv/1399-…`).
2. En Kastideo, introduzca ese número, o **pegue la dirección completa**, y después **Comprobar**.
3. Aparece una vista previa (póster, título, año, sinopsis): si es la correcta, **Usar esta ficha**.

Se necesita una [clave TMDB](help:tmdb). Si la dirección corresponde a una serie mientras corrige una película (o al revés), Kastideo se lo indica.

### Buscar por título

Bajo el código, la búsqueda por título y año ofrece una lista de fichas: pulse la correcta. El número de TMDB se muestra junto a cada resultado.

### Personalizar a mano

**Personalizar la ficha a mano** permite introducir un **título**, un **año**, una **dirección de póster** (https://…) y una **sinopsis**. Estos campos sustituyen a los del proveedor y de TMDB; los campos vacíos no cambian nada. Se combinan con un código TMDB.

### Eliminar una corrección

En la ventana, **Eliminar la corrección** vuelve a la búsqueda automática. **Ajustes > General > Fichas de películas y series** también enumera todas las fichas corregidas (**Fichas corregidas a mano**) con un botón **Eliminar** para cada una.

### Copia de seguridad

Las correcciones forman parte de la **copia de seguridad de la configuración** (Ajustes > Copia de seguridad): acompañan a sus exportaciones e importaciones de un dispositivo a otro.

### Conviene saber

- Para las películas de la suscripción IPTV, la corrección se aplica a la **página de detalles**; la miniatura de la lista conserva la imagen del proveedor.
- Para Mis vídeos, el póster de la lista también se actualiza.

## Ordenar los canales y las categorías {#arranger}

El modo **Ordenar** permite poner **los canales, películas o series de una categoría** en el orden que desee, y también reordenar **las propias categorías**. Está disponible en **Windows, Linux y Android** (aún no en Mac). Funciona tanto con el dedo como con el ratón: la lista se desplaza con normalidad y solo el **tirador ⋮⋮** de la izquierda mueve una fila.

### Reordenar los elementos de una categoría

1. Abra una categoría en la barra lateral (por ejemplo «DEPORTES»).
2. Pulse el botón **Ordenar** (flechas ↑↓) a la derecha del título de la lista.
3. **Mantenga pulsado el tirador ⋮⋮** de una fila y después **arrástrela** a su nuevo lugar. Para desplazar la lista, toque en cualquier sitio que no sea el tirador.
4. Pulse **Terminado** cuando el orden le convenza. Se guarda automáticamente.

Los tres puntos a la derecha de una fila ofrecen:

- **Mover arriba del todo** y **Mover abajo del todo** (práctico en una lista larga);
- **Mover a otra categoría…**: elija una categoría o escriba el nombre de una **nueva lista personal** (por ejemplo «Mis elecciones») para reunir canales de varias categorías;
- **Devolver a su categoría original**.

En la parte superior del modo Ordenar:

- **A → Z** ordena por nombre; **Por número** ordena los canales por número;
- **Orden del proveedor** anula su orden para esta categoría.

Ordenar no está disponible durante una búsqueda ni en Favoritos y Recientes (tienen su propio orden).

### Reordenar las categorías

Abra **Ajustes > Categorías** (o el botón a la derecha del título «Categorías» en la barra lateral). Mantenga pulsado el tirador grande ⋮⋮ a la izquierda de una categoría y arrástrela. **Restablecer** también borra los órdenes y movimientos de canales.

### Copia de seguridad

Su orden, sus listas personales y sus movimientos forman parte de la **copia de seguridad de la configuración** (Ajustes > Copia de seguridad): acompañan a sus exportaciones e importaciones.

## Página de inicio de Directo, Películas y Series {#page-depart}

Por defecto, al abrir **Directo**, **Películas** o **Series** se muestran todos los canales o todos los contenidos, empezando por la primera categoría del proveedor. Puede elegir en su lugar qué se muestra primero.

### Elegir la página de inicio

<!--mac-->
1. Abra **Ajustes (⌘,) > General > Página de inicio**.
<!--/mac-->
<!--pc-->
1. Abra **Ajustes (Ctrl+,) > General > Página de inicio**.
<!--/pc-->
2. Para **Directo**, **Películas** y **Series**, elija por separado:
   - **Todo**: la lista completa (por defecto);
   - **Favoritos** o **Recientes**;
   - **Última vista**: la categoría en la que estaba la última vez;
   - o **una categoría concreta** del proveedor.

### Desde la barra lateral

Haga **clic derecho** en una categoría y después **Definir como categoría de inicio**. El mismo menú permite **dejar de usarla** como categoría de inicio.

### ¿Cuándo se aplica?

Cada vez que abre Directo, Películas o Series desde otra sección (inicio, guía de TV…), incluido al iniciar la aplicación. Una vez en la sección, navega libremente: al hacer clic en **Directo**, **Películas** o **Series** en la barra lateral cuando ya está allí, se muestra la lista completa.

Si la categoría elegida está oculta, renombrada o ya no existe en el proveedor, Kastideo muestra la lista completa. Vuelva a elegirla en los Ajustes.

## Varias cuentas: fuente activa, duplicados y diagnóstico {#sources-multiples}

Cuando tiene **dos o más cuentas IPTV**, Kastideo permite elegir la que se muestra, **sin desactivar** las demás en los ajustes.

### Elegir la fuente activa

- En **Mac**, aparece un menú **Fuente** en la barra lateral. En **Windows, Linux y Android**, el menú **Fuente** está en la barra lateral (en un teléfono: en el menú lateral).
- Elija **Todas las fuentes** o una cuenta concreta. Junto a cada nombre, tres números: **canales · películas · series** devueltos por el proveedor.
- La elección filtra **Directo, Películas, Series, la búsqueda y la guía de TV**, y se **recuerda** entre sesiones.
- Las carpetas y servidores de [Mis vídeos](help:mes-videos) permanecen siempre visibles.

### Fusionar duplicados

Con **Todas las fuentes**, una película o serie ofrecida por varias cuentas (mismo título, mismo año) se muestra **una sola vez**. Desmarque **Fusionar duplicados** para verlo todo. Los favoritos y recientes ya guardados siguen funcionando.

### ¿Por qué dos cuentas del mismo nivel tienen películas distintas?

Los **canales** suelen ser idénticos, pero los **catálogos de películas y series** dependen de la cuenta: muchos proveedores dan a cada cuenta paquetes de vídeo a la carta diferentes. Si los números difieren, lo más frecuente es que sea **cosa del proveedor**.

### El botón Diagnóstico

En **Ajustes > Fuentes**, el botón **Diagnóstico** (estetoscopio) de una cuenta muestra:

- el estado de la cuenta (estado, caducidad, conexiones);
- para canales, películas y series: el número **devuelto por el proveedor**, el número de categorías y el número **realmente mostrado**;
- lo que Kastideo **oculta**: categorías ocultas, contenido para adultos, duplicados fusionados.

Si el «devuelto por el proveedor» difiere entre sus dos cuentas, la diferencia viene del proveedor. El botón **Copiar** le permite adjuntar el resultado a un mensaje para su proveedor.

## Favoritos y recientes {#favoris}

<!--mac-->
- Añada un favorito con la estrella del panel de información, con clic derecho o con **⌘D**.
- La sección **Recientes** conserva los últimos 60 elementos que ha visto.
- **Quitar de recientes**: clic derecho en un elemento > **Quitar de Recientes** (o la tecla **⌫** sobre el elemento seleccionado en la interfaz Clásica). Para varios elementos, haga clic en **Editar**, marque los elementos y después **Eliminar**; **Seleccionar todo** marca toda la lista y **Vaciar todo** vacía el historial.
- Tras una eliminación, un banner **Deshacer** permanece visible unos segundos para restaurarlo todo.
- Los recientes también se pueden vaciar en los ajustes, pestaña **General**.
<!--/mac-->

<!--pc-->
Estrella en la barra del reproductor, tecla **F** o clic derecho > Añadir a favoritos. Los recientes conservan los últimos 60 elementos abiertos.

- **Editar** (junto al título «Recientes»): marque elementos y después **Quitar la selección**, o la cruz de una fila para quitarla sola; **Seleccionar todo** y **Vaciar todo** (de la sección mostrada). **Terminado** vuelve a la lista.
- Clic derecho en un elemento > **Quitar de recientes**.
- Ajustes > General > **Vaciar recientes** los borra todos, de todas las secciones.
<!--/pc-->

## Alertas y notificaciones {#alertes}

<!--pc-->
- **Avisarme cuando empiece** en los detalles de un programa próximo (campana en la guía).
- **Palabras clave** (Ajustes > Grabaciones): un programa cuyo título contenga una palabra clave activa una alerta, en sus canales favoritos o en todos.
- La alerta se muestra arriba a la derecha de Kastideo con **Ver**, y la ventana reaparece si estaba minimizada.
- **Notificaciones del sistema** (Ajustes > General > Notificaciones, activadas por defecto): las alertas, el inicio y el final de grabaciones y las descargas terminadas o fallidas también aparecen en el centro de notificaciones de Windows o Linux, incluso cuando Kastideo está detrás de otra ventana. Al hacer clic en la notificación, Kastideo vuelve al primer plano.
<!--/pc-->

## Apariencia {#apparence}

<!--pc-->
Ajustes > **Apariencia**:

- **Tema**: **Oscuro** (por defecto), **Claro** o **Igual que el sistema** (sigue a Windows o Linux). El reproductor, la interfaz TV, MultiVista, la pantalla de inicio, las páginas de detalles y el banner destacado permanecen oscuros, como en Mac.
- **Color de acento**: por defecto (azul Kastideo), azul, morado, rosa, rojo, naranja, verde o turquesa; se usa para selecciones, botones e interruptores.
- **Densidad de lista** (interfaz Clásica): compacta, estándar o espaciosa.
- **Tamaño de miniaturas** (interfaz Cine): pequeño, mediano o grande.
- **Interfaz** por tipo de contenido y **banner destacado** (véase [Tres interfaces](help:interfaces)).

Los cambios se aplican de inmediato, sin reiniciar.
<!--/pc-->

# YouTube

## YouTube: explorar y reproducir {#youtube}

La sección **YouTube** (barra lateral, botón de Inicio,
<!--mac-->**⌘9**<!--/mac--><!--pc-->**Ctrl+9**<!--/pc-->) funciona en dos pasos: primero un **explorador** y después el **reproductor** en cuanto elige un vídeo.

![Del explorador al reproductor](img:youtube)

### El explorador

- **Mis canales**: pegue un enlace de canal o su @identificador en el campo superior para seguirlo. Sus últimos vídeos aparecen en una fila, sin clave ni cuenta. Para traer todas sus suscripciones de una vez: [Importar mis suscripciones](help:youtube-import).
- **Búsqueda**: escriba su búsqueda en el mismo campo (resultados con miniaturas, ordenados por relevancia, fecha o visualizaciones, más páginas). Requiere una **clave de API de Google gratuita**: [la guía paso a paso](help:youtube-cle).
- **Enlaces pegados**: un vídeo se reproduce, una lista de reproducción pasa a ser la cola de reproducción, un canal se sigue.
- **Favoritos e historial**: clic derecho en una miniatura; el historial conserva los últimos 80 vídeos (con un botón para vaciarlo).
- **Ver más tarde**: clic derecho en una miniatura para reservar un vídeo. Un vídeo que ha empezado **se reanuda donde lo dejó** (una barra roja muestra el progreso); sale de la lista cuando se ha visto hasta el final.

### El reproductor

<!--mac-->
Al hacer clic en un vídeo, el reproductor sustituye al explorador; la lista de la que viene pasa a ser la cola. Los botones Anterior / Siguiente, **Reproducción automática del siguiente**, **Bucle**, **Silencio** y **Abrir en YouTube** están en una barra que se oculta sola; **Esc** o **Explorador de YouTube** le devuelve a la lista.
<!--/mac-->
<!--pc-->
Al hacer clic en un vídeo, el reproductor se abre en **su propia ventana** (Edge o Chrome en Windows, Chrome o Chromium en Linux en modo «aplicación»; si no, su navegador predeterminado); la lista de la que viene pasa a ser la cola. Los botones Anterior / Siguiente, **Reproducción automática del siguiente**, **Bucle**, **Silencio** y **Abrir en YouTube** están en una barra que se oculta sola. Un banner en Kastideo le recuerda el vídeo actual, con **Volver a abrir la ventana**.
<!--/pc-->

La reproducción IPTV se detiene mientras se reproduce YouTube (salvo que haya una grabación en curso).

> Sobre los anuncios y su cuenta de Google: véase [Anuncios, cuenta y privacidad](help:youtube-confidentialite).

## Importar mis suscripciones de YouTube {#youtube-import}

YouTube no permite que una aplicación como Kastideo inicie sesión en su cuenta. Google sí permite **exportar sus datos**: solo pide su lista de suscripciones, un pequeño archivo `subscriptions.csv` que Kastideo lee **en su ordenador**.

![Los pasos de la importación](img:takeout)

### Paso 1: pedir la exportación a Google

1. Abra [Google Takeout](https://takeout.google.com/) con la sesión iniciada en la **cuenta de Google** cuyas suscripciones desea.
2. Haga clic en **Anular la selección de todo** (en la parte superior de la lista).
3. Desplácese hasta **YouTube y YouTube Music** y marque la casilla.
4. Haga clic en **Se incluyen todos los datos de YouTube**, haga clic en **Anular la selección de todo**, marque solo **suscripciones** y después **Aceptar**.
5. Al final de todo, haga clic en **Paso siguiente**. Mantenga **Enviar enlace de descarga por correo electrónico**, **Exportar una vez** y el formato **.zip**, y haga clic en **Crear exportación**.
6. Google prepara el archivo (unos minutos, a veces más) y le envía un correo. Haga clic en **Descargar archivos** en el correo y guarde el `.zip`.

### Paso 2: encontrar el archivo

1. Abra el `.zip`: <!--mac-->haga doble clic en él en el Finder<!--/mac--><!--pc-->clic derecho > **Extraer todo** (Windows) o doble clic (Linux)<!--/pc-->.
2. Abra **Takeout** > **YouTube y YouTube Music** > **suscripciones**.
3. El archivo se llama **subscriptions.csv** (o tiene un nombre en el idioma de su cuenta, por ejemplo **abonnements.csv** si su cuenta está en francés).

### Paso 3: importarlo en Kastideo

1. Abra **YouTube** > **Mis canales**.
2. Haga clic en **Importar mis suscripciones…** y elija el archivo.
3. Kastideo añade los canales y carga sus últimos vídeos (con muchas suscripciones, la primera actualización puede tardar un minuto).

> Los canales que ya sigue no se añaden dos veces. El archivo solo lo lee Kastideo, en su equipo: no se envía nada a Google ni a ningún otro sitio, y Kastideo nunca accede a su cuenta.

### Si no funciona

- **«No se ha encontrado ningún canal nuevo en este archivo»**: no es el archivo correcto (por ejemplo, el historial de reproducciones), o los canales ya se siguen. Vuelva al paso 2.
- **Ningún correo de Google**: revise la carpeta de correo no deseado, o vuelva a [Google Takeout](https://takeout.google.com/): la sección «Gestionar exportaciones» permite descargar de nuevo el archivo.
- **No hay carpeta «suscripciones»**: en el paso 1.4, compruebe que marcó la casilla **suscripciones**.
- Sin archivo, puede seguir un canal cada vez pegando su enlace o su @identificador: véase [YouTube](help:youtube).

## Obtener una clave de API de Google (búsqueda) {#youtube-cle}

La **búsqueda** de YouTube usa la interfaz oficial de Google («YouTube Data API v3») con **su propia clave**. Es **gratuita** y suficiente para unas **100 búsquedas al día**. Sin clave, todo lo demás funciona: seguir canales, reproducir enlaces pegados, favoritos, historial.

### Crear la clave (5 minutos, una sola vez)

1. Abra la [consola de Google Cloud](https://console.cloud.google.com/) e inicie sesión con una cuenta de Google.
2. Arriba, haga clic en el selector de proyectos > **Proyecto nuevo**. Póngale un nombre (por ejemplo «Kastideo»), haga clic en **Crear** y selecciónelo.
3. Abra [la página de YouTube Data API v3](https://console.cloud.google.com/apis/library/youtube.googleapis.com) y haga clic en **Habilitar**.
4. Menú **APIs y servicios > Credenciales** > **Crear credenciales** > **Clave de API**.
5. Copie la clave mostrada (unos cuarenta caracteres que empiezan por «AIza»).
6. Opcional pero recomendado: **Editar clave** > **Restricciones de API** > **Restringir clave** > marque **YouTube Data API v3**.

### Dársela a Kastideo

1. Abra **Ajustes > General > YouTube**.
2. Pegue la clave en **Clave de API de Google** y confirme.
3. Vuelva a **YouTube**: la búsqueda ya funciona.

<!--mac-->
La clave se guarda en el **llavero de macOS**, nunca en claro en el disco, y nunca se publica.
<!--/mac-->
<!--pc-->
La clave se guarda en la **cámara acorazada del sistema** y nunca se publica.
<!--/pc-->

> Cuota: cada búsqueda consume 100 de las 10 000 unidades gratuitas diarias. Si alcanza el límite, Kastideo muestra «Error de la API de YouTube»; la búsqueda vuelve al día siguiente. Seguir canales y reproducir vídeos no usa esta cuota.

### Cuando algo falla

- **«Falta la clave de API»**: no hay nada guardado en los Ajustes.
- **«Clave de API no válida» / «Error de la API de YouTube»**: la clave se copió mal, o no se hizo el paso 3 (habilitar la API) para **este** proyecto.
- **Error de restricción**: si restringió la clave, compruebe que **YouTube Data API v3** está marcada.

## Anuncios, cuenta y privacidad {#youtube-confidentialite}

### Anuncios

Kastideo usa el **reproductor oficial de YouTube en «modo de privacidad mejorada»** (youtube-nocookie.com), el que Google ofrece a los sitios web para incrustar vídeos: no instala ninguna cookie de seguimiento y, por tanto, no muestra anuncios personalizados, normalmente ninguno.

**Esto no es un bloqueador de anuncios**: no se intercepta ni se elude nada, y YouTube sigue siendo libre de mostrar anuncios, que financian a los creadores.
<!--pc-->
Si su navegador tiene su propio bloqueador de anuncios, se aplica en la ventana del reproductor.
<!--/pc-->

### ¿Por qué no puedo iniciar sesión en mi cuenta?

El reproductor con privacidad mejorada no reconoce su cuenta: no hay recomendaciones personalizadas, ni suscripciones sincronizadas automáticamente, ni YouTube Premium (que quita los anuncios en youtube.com, no en un reproductor incrustado). Ese es el precio de una reproducción sin rastreo. Para recuperar sus suscripciones, use la [importación paso a paso](help:youtube-import).

### Qué conserva Kastideo

Sus canales seguidos, favoritos, historial (80 vídeos), lista «ver más tarde» y puntos de reanudación se guardan **solo en su ordenador**. Cualquier clave de API permanece en la cámara acorazada del sistema. No se envía nada a Kastideo ni a nadie que no sea YouTube / Google cuando busca o reproduce un vídeo.

# Ajustes y mantenimiento

## Atajos de teclado {#raccourcis}

<!--mac-->
- **⌘0**: Inicio
- **⌘1 a ⌘7**: Directo, Películas, Series, Favoritos, Recientes, Grabaciones, Guía TV
- **⌥⌘1 / ⌥⌘2 / ⌥⌘3**: interfaz Clásica / Cine / TV (para el tipo de contenido mostrado)
- Interfaz TV: **↑ ↓** zapping, **←** panel de canales, cifras = número de canal, **I** banner, **B** canal anterior, **G** guía de TV, **H** inicio, **F** favorito, **M** silencio
- **⌘↑ / ⌘↓**: elemento anterior / siguiente (zapping)
- **⌘K**: reproducir / pausa
- **⌘[ / ⌘]**: retroceder 10 s / avanzar 30 s (películas y episodios)
- **⌘↩** o doble clic en el vídeo: modo cine (Esc para salir)
- **⌘.**: detener la reproducción
- **⇧⌘R**: grabar el canal que se está viendo / detener la grabación
- **⌥⌘L**: registro
- **⌘D**: añadir o quitar de favoritos
- **⌘R**: actualizar todas las fuentes
- **⌘,**: ajustes y fuentes
- **⌘?**: esta ayuda (se abre en la página de la pantalla actual)
- **⌘8**: Mis vídeos, **⌘9**: YouTube
<!--/mac-->

<!--pc-->
- **Ctrl+0**: inicio — **Ctrl+1**: directo — **Ctrl+2**: películas — **Ctrl+3**: series — **Ctrl+7**: guía de TV — **Ctrl+Alt+M**: MultiVista — **Ctrl+,**: ajustes
- **Espacio**: reproducir / pausa — **M**: sonido — **F**: favorito — **R**: grabar / detener — **← / →**: −10 s / +30 s — **Ctrl+.**: detener la reproducción
- **Ctrl+Enter** o doble clic en la imagen: modo cine — **F11**: pantalla completa — **Esc**: salir del modo cine, volver a los detalles o a las filas
- Interfaz TV: **↑ / ↓** zapping, **cifras** número de canal, **←** panel, **→ / I** banner, **B** canal anterior, **G** guía, **H** inicio
- MultiVista: **1 a 4** sonido, **G** ampliar, **A** añadir, **Supr** quitar, **F** pantalla completa, **Esc** salir
- **Ctrl+Alt+L**: registro
- **Ctrl+8**: Mis vídeos, **Ctrl+9**: YouTube
- **F1**: esta ayuda (se abre en la página de la pantalla actual)
<!--/pc-->

## Ajustes generales {#reglages}

<!--mac-->
- **Idioma** (pestaña **General**): Kastideo está disponible en **francés, inglés, español, alemán, italiano y portugués**. El idioma se elige en el primer inicio y después se puede cambiar en **Ajustes > General > Idioma** (o «Sistema» para seguir el idioma del Mac). El cambio se aplica tras reiniciar la aplicación, cosa que Kastideo se ofrece a hacer por usted. La ayuda y los menús siguen el idioma elegido; las notas de versión permanecen en francés.
- **Apariencia** (pestaña **Apariencia**): tema oscuro (por defecto), claro o igual que el sistema; **color de acento** (Sistema, azul, morado, rosa, rojo, naranja, verde, turquesa); **interfaz** Clásica o Cine para cada tipo de contenido; **densidad de lista** (compacta, estándar, espaciosa) para la interfaz Clásica; **tamaño de miniaturas** (pequeño, mediano, grande) para la interfaz Cine.
- **Fichas de películas y series** (pestaña **General**): clave de API de **TMDB** opcional (gratuita en themoviedb.org > Ajustes > API; clave v3 o token de lectura v4), guardada en el llavero. **Guardar y comprobar** la verifica. Sin clave, los detalles proceden de su proveedor IPTV.
- **Actualizar al iniciar**: vuelve a cargar las fuentes cuya última actualización tiene más de 6 horas.
- **Caché**: Kastideo conserva una copia local de las listas y de la guía de TV para arrancar al instante. **Vaciar y recargar** borra esta copia y reinicia la carga.
<!--/mac-->

<!--pc-->
- **General**: idioma (en el próximo inicio), reanudar la reproducción, relé de emisión, actualizar al iniciar, vaciar recientes, **conexiones simultáneas** (MultiVista), **notificaciones del sistema**, guía de TV y guía de respaldo, contenido para adultos (oculto por defecto), clave TMDB, **inicio y archivos .m3u**, **actualizaciones**.
- **Apariencia**: tema, color de acento, densidad de lista, tamaño de miniaturas, interfaces, banner destacado.
- **Fuentes**: añadir, actualizar, eliminar, estado de la guía.
- **Categorías**: orden, ocultación, nombres, palabras clave.
- **Grabaciones**: carpeta, formato, márgenes, descargas, diferido, alertas.
- **Copia de seguridad**: exportar o importar la configuración.
<!--/pc-->

## Obtener una clave TMDB (gratuita) {#tmdb}

<!--mac-->
TMDB (The Movie Database) es una base de datos colaborativa de cine y televisión. Su clave es **gratuita** para uso personal; permite a Kastideo mostrar fotos del reparto, pósteres y fondos en HD, el tráiler y una sinopsis traducida.

1. Cree una cuenta en **themoviedb.org** («Join TMDB») y confírmela con el enlace enviado por correo.
2. Con la sesión iniciada, abra **themoviedb.org/settings/api** (avatar > Ajustes > API), o haga clic en **Obtener una clave gratuita** en los ajustes de Kastideo.
3. Haga clic en **Create**, elija **Developer** y acepte las condiciones de uso.
4. Rellene el formulario: tipo de uso **Personal**, nombre de la aplicación **Kastideo**, URL **https://github.com/jihemezes/kastideo**, un breve resumen («Reproductor IPTV personal, muestra los detalles de las películas») y después sus datos de contacto.
5. Envíelo: la página muestra una **API Key** (32 caracteres) y un **API Read Access Token** (largo, empieza por «eyJ»). Kastideo acepta cualquiera de los dos; la clave de API es más fácil de copiar.
6. En Kastideo: **Ajustes (⌘,) > General > Fichas de películas y series**, pegue la clave y haga clic en **Guardar y comprobar**. «Clave válida ✓» lo confirma.
7. Vuelva a abrir una página de detalles (o haga clic en **Actualizar** al final): ahora la completa TMDB.

La clave se guarda en el llavero del Mac. **Quitar la clave** vuelve a usar solo la información del proveedor IPTV.
<!--/mac-->

<!--pc-->
Cree una cuenta en themoviedb.org, después **Ajustes > API** y solicite una clave (uso personal). Pegue la «clave de API» (v3) o el «token de acceso de lectura» (v4) en Ajustes > General y después **Guardar**. Los detalles se enriquecen (pósteres, reparto, tráileres, sinopsis y episodios en su idioma).
<!--/pc-->

## Pósteres y sinopsis de sus vídeos personales {#tmdb-perso}

Para las películas y series de sus **carpetas**, Kastideo puede buscar el póster y la sinopsis en **TMDB** (se necesita una [clave TMDB](help:tmdb)).

Como un nombre de archivo no tiene año ni etiqueta, la búsqueda es **prudente**: solo se acepta una coincidencia si su **título (o título original) es exactamente el nombre del archivo**. Los nombres pegados con mayúsculas interiores (**TearsOfSteel**) se separan (Tears Of Steel). Los nombres enteramente en minúsculas pegadas («bigbuckbunny») no se reconocen.

- Ajuste: en **Ajustes**, sección **Fichas de películas y series**: **Buscar también los vídeos personales**. Activado por defecto; desactívelo para evitar cualquier búsqueda.
- Si falta una coincidencia o es errónea (por ejemplo, dos películas comparten el mismo título), use [Corregir la ficha](help:corriger-fiche): puede vincular la película al **código TMDB** correcto.

## Inicio y archivos .m3u {#demarrage}

<!--pc-->
Ajustes > General > **Inicio y archivos**:

- **Iniciar Kastideo al iniciar sesión** (Windows y Linux) e **Iniciar minimizado** en la barra de tareas: las grabaciones programadas y las alertas solo se realizan mientras Kastideo está abierto.
- **Abrir los archivos .m3u y .m3u8 con Kastideo** (opcional): al hacer doble clic en una lista de reproducción, se ofrece añadirla como fuente (Ajustes > Fuentes); si Kastideo ya está abierto, la ventana existente la recibe. Si Windows sigue abriendo otro programa, clic derecho en el archivo > Abrir con > Elegir otra aplicación > Kastideo. En Linux, la asociación se guarda en su perfil (archivo `~/.config/mimeapps.list`); si aparece un mensaje de error bajo el interruptor, indica la causa.

Ambas opciones también las ofrece el instalador de Windows (sin marcar por defecto).
<!--/pc-->

## Copia de seguridad y transferencia {#sauvegarde}

<!--mac-->
Ajustes > General > **Copia de seguridad y transferencia**:

- **Exportar la configuración…** guarda un archivo `Kastideo-configuration.json`: fuentes (Xtream y listas M3U por dirección), favoritos, recientes, categorías personalizadas (orden, ocultas, nombres, palabras clave), interfaces elegidas y clave TMDB. Marque **Incluir las contraseñas** para no tener que escribir nada de nuevo; guarde el archivo en un lugar seguro.
- **Importar la configuración…** añade el contenido de un archivo: en un Mac nuevo, o desde Kastideo para Windows y Linux (mismo formato). Las fuentes ya presentes se reconocen y no se elimina nada.

Los servidores Jellyfin, Emby y Plex se exportan (con su contraseña o token si marca **Incluir las contraseñas**). Las listas M3U añadidas como archivos locales y las carpetas no se importan en otro Mac (los archivos no existen allí o hay que volver a elegirlos).
<!--/mac-->

<!--pc-->
Ajustes > **Copia de seguridad**: **Exportar la configuración…** (fuentes y su guía, contraseñas si lo desea, favoritos, recientes, categorías, interfaces, apariencia, número de conexiones, contenido para adultos, banner, clave TMDB) e **Importar la configuración…**. El archivo es el mismo que el de Kastideo para Mac: puede pasar de un ordenador a otro en ambos sentidos. No se elimina nada al importar. Los servidores Jellyfin, Emby y Plex están incluidos (también la contraseña o el token, si se solicita); las carpetas también, con sus rutas (que habrá que corregir si difieren en este ordenador).
<!--/pc-->

## Actualizaciones {#mises-a-jour}

<!--mac-->
Kastideo se actualiza solo gracias a **Sparkle**, la herramienta de referencia para las aplicaciones de Mac distribuidas fuera de la App Store.

- **Al iniciar** (unos segundos después de arrancar), y después una vez al día si Kastideo permanece abierto, Kastideo comprueba discretamente si hay una versión nueva disponible en GitHub.
- Si la hay, un **banner** en la parte superior de la ventana la anuncia, **nunca mientras ve o graba** (espera a que termine la reproducción). La actualización es **opcional**: **Actualizar…** abre la ventana de notas de versión y después **Instalar la actualización** (Kastideo se cierra, instala y se vuelve a abrir); **Más tarde** oculta el banner hasta el siguiente inicio; **Omitir esta versión** deja de ofrecerla (se ofrecerá la siguiente).
- Puede comprobarlo en cualquier momento con **Kastideo > Buscar actualizaciones…**.
- Cada actualización está firmada: Kastideo se niega a instalar un archivo que no procede de su editor.

En **Ajustes > Actualizaciones**:

- **Buscar actualizaciones al iniciar**: activa o desactiva la comprobación al iniciar y la diaria.
- **Recibir versiones de prueba (beta)**: ofrece también versiones beta, que aportan novedades antes pero pueden ser menos estables. Desactive la opción para volver a las versiones estables en la siguiente actualización.

> Las versiones 0.1.0 y anteriores no pueden actualizarse solas: instale la 0.2.0 a mano una vez y las siguientes llegarán por sí solas.
<!--/mac-->

<!--pc-->
Kastideo busca nuevas versiones en GitHub al iniciar y después cada 12 horas (versiones preliminares de Windows / Linux, mientras estas versiones están en vista previa).

- Una versión nueva se anuncia con un **banner abajo a la derecha**, solo cuando no está viendo nada. **Ver** abre la ventana de actualización con sus notas de versión; la cruz la pospone.
- **Instalar y reiniciar** descarga el archivo que corresponde a su instalación y después:
  - **Windows, instalado**: ejecuta el nuevo instalador en silencio y después reinicia Kastideo;
  - **Windows, portátil**: sustituye los archivos de la carpeta tras cerrar y después reinicia Kastideo;
  - **AppImage**: guarda el nuevo AppImage junto al antiguo, elimina el antiguo y lo inicia;
  - **Paquete .deb**: lo instala con apt (se pide su contraseña) y después reinicia Kastideo.
- Una grabación en curso se termina correctamente antes de cerrar.
- **Omitir esta versión**: no se volverá a ofrecer (una comprobación manual la ofrece de nuevo).
- Ajustes > General > **Actualizaciones**: versión instalada y tipo de instalación, **Comprobar ahora**, comprobaciones automáticas, **Novedades de las versiones recientes**, página de versiones en GitHub.
- En el primer inicio tras una actualización, la ventana **Novedades** resume los cambios.
<!--/pc-->

## Instalación {#installation}

<!--pc-->
- **Windows (recomendado)**: ejecute **Kastideo-…-windows-x64-setup.exe**. Por defecto, Kastideo se instala solo para usted, sin derechos de administrador (en su carpeta AppData); el instalador también ofrece instalar para todos los usuarios, un icono en el escritorio, abrir archivos .m3u e iniciar al iniciar sesión. Desinstalar: Configuración de Windows > Aplicaciones > Kastideo.
- **Windows, portátil**: descomprima el archivo «windows-x64.zip» donde quiera y ejecute **kastideo.exe** (no se instala nada; las actualizaciones sustituyen los archivos de la carpeta).
- La aplicación no está firmada: si SmartScreen dice «Windows protegió su PC», haga clic en **Más información** y después en **Ejecutar de todos modos**.
- **Zorin OS 17 / Ubuntu 22.04**: paquete «ubuntu22.04_amd64.deb» (doble clic o `sudo apt install ./kastideo_…deb`).
- **Zorin OS 18 / Ubuntu 24.04**: paquete «ubuntu24.04_amd64.deb».
- **Cualquier distribución y Raspberry Pi (64 bits)**: archivo AppImage; hágalo ejecutable (clic derecho > Propiedades > Permitir ejecutar, o `chmod +x`) y ejecútelo.
<!--/pc-->

## Kastideo en Android y Android TV {#android}

Kastideo también está disponible para **teléfonos y tabletas Android** y para **Android TV** (Google TV, Chromecast con Google TV, Nvidia Shield, televisores Philips, Sony, TCL…). Es la misma aplicación, con las mismas fuentes, categorías, favoritos, guía, replay, grabaciones, MultiVista y YouTube, adaptada al táctil y al mando a distancia. Un único archivo **APK** sirve para teléfonos y televisores.

### Elegir el archivo correcto

En la página de versiones de GitHub, busque los archivos `Kastideo-…-android-….apk`:

- **arm64-v8a**: casi todos los teléfonos, tabletas y cajas de TV recientes (la elección correcta en caso de duda);
- **armeabi-v7a**: dispositivos antiguos y algunas cajas de TV de 32 bits;
- **x86_64**: emuladores y algunas tabletas Intel;
- **universal**: todos los procesadores, pero más grande.

### Instalar sin desactivar la seguridad

Android **no** le obliga a desactivar sus protecciones: pide un permiso para **una sola aplicación** (la que abre el APK: navegador, administrador de archivos o Downloader).

1. Descargue el APK y ábralo.
2. Si Android dice «Por su seguridad, la instalación de aplicaciones desconocidas está bloqueada», pulse **Ajustes** y active **Permitir desde esta fuente** para la aplicación que está usando (Chrome, por ejemplo). Las demás siguen bloqueadas.
3. Vuelva atrás y pulse **Instalar**.
4. Si **Play Protect** señala una aplicación de un desarrollador desconocido, pulse **Más detalles** y después **Instalar de todos modos**: Kastideo no está publicado en Google Play y está firmado por su desarrollador, no por un editor registrado en Google.

Todos los APK de Kastideo están firmados con la misma clave: Android acepta, por tanto, las actualizaciones sobre la instalación existente, sin perder sus ajustes.

### Instalar en Android TV

Un televisor suele no tener navegador ni administrador de archivos. Tres métodos:

- **Downloader** (aplicación gratuita de la Play Store del televisor): escriba la dirección de descarga del APK de GitHub y después permita a Downloader instalar aplicaciones;
- **Memoria USB**: copie el APK en la memoria, conéctela al televisor y ábralo con un administrador de archivos (Solid Explorer, File Commander…);
- **Desde su teléfono**: envíe el APK con «Send Files to TV», o instálelo con `adb install` si la depuración por red está activada.

Kastideo aparece entonces en la lista de aplicaciones del televisor con su banner.

### Uso táctil (teléfono, tableta)

- **Menú ☰** arriba a la izquierda: las secciones (Directo, Películas, Series, Favoritos, categorías…) se abren en un panel lateral.
- **Pulsación larga** en un canal, una película o un episodio: el menú (favorito, grabar, replay, decodificación por software…), como un clic derecho en un ordenador.
- **En el reproductor**: un toque muestra u oculta la barra; **doble toque** a la izquierda = −10 s, a la derecha = +30 s, en el centro = pausa; **deslizar verticalmente** a la derecha = volumen, a la izquierda = brillo; **deslizar horizontalmente** = avanzar o retroceder en una película.
- **Atrás** (gesto o botón de Android): cierra el reproductor y después vuelve a la pantalla de inicio.
- Gire el dispositivo a **horizontal**: el canal actual pasa a pantalla completa.

### Uso del mando a distancia (Android TV)

En Android TV, Kastideo muestra pantallas pensadas para el mando: el elemento seleccionado aparece **con contorno naranja, ampliado y luminoso**, como en Apple TV.
- **Flechas**: mueven la selección; **OK** confirma; **Atrás** vuelve (reproductor → episodios → ficha → lista → inicio).
- **Inicio**: Directo, Películas, Series, luego Ajustes y Registro.
- **Películas y series**: categorías arriba (**←/→**), carátulas debajo. **OK** abre la ficha; en una serie, **Episodios** muestra las temporadas (**←/→**) y los episodios (**↑/↓**).
- **Directo**: **↑ / ↓** o **Canal +/−** cambian de canal, los **números** introducen un canal, **←** abre la lista de canales, **→** muestra el banner de información. En la lista, **↑ / ↓** recorren los canales **sin cambiar de canal** y **OK** reproduce el resaltado; sube hasta arriba para elegir la **categoría** con **←/→**; **Menú** añade a favoritos.
- **Durante la reproducción**: **OK** = pausa, **←/→** = −10 s / +30 s, **↑ / ↓** = volumen; se admiten las teclas Reproducir/Pausa y Avance/Retroceso rápido.
- **Añadir una fuente sin teclado**: Ajustes > **Añadir una fuente con mi teléfono**. El televisor muestra un **código QR** y un código de 4 cifras; en el teléfono (misma red Wi-Fi), abre la dirección, introduce el código y los datos de la fuente (Xtream o lista M3U). **Quitar una fuente** está en el mismo sitio.
- **Registro**: botón Registro del inicio, o tecla **Menú**, **Info** o **roja** del mando desde cualquier pantalla. **↑ / ↓** desplazan, **OK** muestra solo los errores.

### Diferencias con el ordenador

- **Vídeos locales (galería)**: Ajustes > Fuentes > **Añadir los vídeos de la galería** (o Añadir una fuente > **Galería** para **elegir álbumes**: Cámara, Capturas de pantalla…). Los vídeos del teléfono aparecen en **Mis vídeos** con su miniatura, ordenados por fecha; una película bien nombrada (título exacto) obtiene su póster y su sinopsis de TMDB. Android pide acceso a los vídeos: desde Android 14 puede permitir solo una **selección** (botón «Elegir más vídeos…»). No se copia ni se envía nada a otro sitio.
- **Cast**: en Android, el envío a un Chromecast o a un televisor usa el **modo directo**: la dirección de la emisión se envía tal cual al televisor (los canales pasan a HLS «.m3u8»). Los archivos locales (Mis vídeos) no se pueden enviar. La conversión con ffmpeg disponible en los ordenadores no está disponible.
- Las **grabaciones y descargas** se guardan en la carpeta de la aplicación (`Android/data/fr.jmezes.kastideo/files/Movies`, visible desde el administrador de archivos). Android puede detener una aplicación que se ejecuta en segundo plano: mantenga Kastideo abierto y el dispositivo enchufado durante una grabación. Una grabación programada solo empieza si Kastideo se está ejecutando a la hora prevista.
- **Sin inicio al iniciar sesión** ni asociación de archivos .m3u: añada sus listas en Ajustes > Fuentes.
- **YouTube** se abre en el navegador del dispositivo.

### Actualizaciones

Kastideo busca nuevas versiones de Android en GitHub. Cuando se ofrece una, **Instalar** descarga el APK y Android le pide que confirme. La primera vez, Android también le pide que permita a Kastideo instalar aplicaciones (el ajuste se abre solo). Una vez instalada la actualización, **vuelva a abrir Kastideo**: Android cierra la aplicación durante la instalación.

### Si algo falla

- **«Aplicación no instalada»**: ya hay instalada otra copia de Kastideo firmada con otra clave; desinstálela primero.
- **«Error al analizar» o «Aplicación no compatible»**: archivo equivocado para su procesador; pruebe el APK **universal**.
- **Imagen congelada**: véase la página «Imagen congelada: decodificación por software».
- **El Registro de reproducción** (Ajustes) conserva los detalles de los errores de reproducción.

## Kastideo Compat: Mac antiguos (macOS 12 y 13) {#mac-compat}

La versión **Mac** de Kastideo requiere **macOS 14 Sonoma** o posterior. Para los Mac más antiguos, **Kastideo Compat** es la versión «Windows / Linux» reconstruida para Mac: **macOS 12 Monterey y posteriores**, Intel o Apple Silicon.

**Instalación.** Descargue `Kastideo-Compat-…-macos.dmg` desde la página de [Releases](https://github.com/jihemezes/kastideo/releases) (versiones preliminares cuyo número termina en `-desktopN`), ábralo y arrastre **Kastideo Compat** a **Aplicaciones**. La aplicación está firmada y notarizada por Apple. Se puede instalar **junto a** la versión nativa.

**En qué se diferencia de la versión nativa para Mac.**

- La interfaz y las funciones son las de la versión de Windows y Linux (motor de reproducción mpv): directo, guía de TV, temas, MultiVista, grabación, películas y series, YouTube…
- Los atajos usan la tecla **Comando** (⌘) en lugar de Ctrl: ⌘1, ⌘2, ⌘3… para las secciones, ⌘, para los ajustes, ⌘K para pausa.
- **Sin actualización automática**: el banner de nueva versión abre la página de descarga.
- **Enviar a un televisor** necesita **ffmpeg** (por ejemplo `brew install ffmpeg` con Homebrew). Sin ffmpeg, todo lo demás funciona con normalidad.
- Las grabaciones se guardan en **Películas > Kastideo**.
- No se ofrecen el inicio al iniciar sesión ni la asociación de archivos .m3u.

Los ajustes y las fuentes se pueden trasladar entre versiones con **Copia de seguridad y transferencia**.

## Kastideo en iPhone y iPad {#ios}

**Kastideo para iPhone y iPad** (iOS 17 o posterior) se distribuye mediante **TestFlight**, el servicio de Apple para probar aplicaciones antes de su lanzamiento. No hay ningún archivo que instalar a mano: recibe una invitación, instala la aplicación **TestFlight** desde la App Store y después **Kastideo** desde TestFlight. Las actualizaciones llegan a través de TestFlight.

**Primer inicio.** Lea y acepte el aviso legal. En la pantalla de inicio, pulse **Añadir una fuente** (Xtream Codes o lista M3U), o vaya a **Ajustes > Importar la configuración…** para traer sus fuentes, favoritos y categorías desde Mac, Windows, Linux o Android (véase «Copia de seguridad y transferencia»). Consejo: guarde el archivo de configuración en **iCloud Drive** para encontrarlo en todos sus dispositivos. Para probar sin suscripción, toque **Probar la demo**: Kastideo añade unos vídeos libres de derechos.

**Qué ofrece la aplicación.**

- **Inicio**: sobre un fondo degradado con el logotipo, los grandes mosaicos **Directo, Películas, Series, YouTube** y **Mis vídeos** (si tiene una galería, carpeta o servidor), con su número de elementos; debajo, los botones **Continuar, Recientes, Favoritos, Guía TV** y **Grabaciones**, y un campo de búsqueda arriba. **Continuar / Recientes / Favoritos** abren una página de cuadrícula: mantenga pulsado un elemento o pulse **Seleccionar** para quitar varios, **Vaciar todo** en el menú ⋯ y **Deshacer** justo después de una eliminación.
- **Barra inferior**: **Inicio** (vuelve a la pantalla de inicio desde cualquier pantalla), **Contenido** (fuentes, galería, categorías, páginas de detalles TMDB, YouTube, iCloud, copia de seguridad), **App** (reproducción, MultiVista, grabaciones, replay, Cine, apariencia, acerca de) y **Ayuda**. Las menciones «Ajustes > …» de esta página pertenecen a una de estas dos familias.
- **MultiVista en vertical**: con la pantalla en vertical, las pantallas de MultiVista se **apilan** (una sobre otra, a todo el ancho) en lugar de ir una junto a otra; en horizontal se mantiene la disposición elegida.
- **Apple TV** (beta): recibe su configuración desde el iPhone (Ajustes > Copia de seguridad > Enviar al Apple TV), insignias de «visto»; guía que se reabre en la última posición (ajuste); existe la misma aplicación para Apple TV (tvOS 17): vistas Clásica, Cine y TV (Directo), elegidas por tipo de contenido (botón «Vista» o Ajustes > Vista); Inicio con mosaicos (como en iPad), Mis vídeos (Emby, Jellyfin, Plex), Directo, Películas, Series, una Guía TV en cuadrícula horaria (ventana de 3 h, replay de programas) y un reproductor con mando a distancia (↑ / ↓ cambian de canal; clic = pistas de audio, subtítulos, velocidad, último canal, número de canal; episodio siguiente automático). Pestaña Búsqueda, favoritos (pulsación larga), temporizador de apagado. Ajustes: fuentes editables, página de inicio, categorías, zapping (con confirmación o directo). Añada fuentes desde un teléfono (código QR + código de 4 cifras, Ajustes > Añadir desde un teléfono; el formulario se adapta al tipo de fuente y acepta la clave TMDB) o con el teclado; la sincronización con iCloud Drive no está disponible en Apple TV.
- **Visto y guía**: insignia en los pósteres vistos, «Marcar como visto» (detalle, pulsación larga en un episodio, temporada); ajuste «Al abrir la guía» (Ajustes > Replay).
- **Categorías (Directo, Películas, Series)**: en vista de Lista o Cuadrícula, la **barra superior** (Todo, Favoritos, Recientes y después cada categoría) cambia de categoría con un toque; el botón ▦ de la izquierda abre la **lista completa** con búsqueda y número de elementos.
- **Directo**: el botón de arriba a la izquierda cambia la visualización: **Lista** (canales con el programa actual, búsqueda, categorías, favoritos; deslice un canal hacia la izquierda), **Cine** (un banner «destacado», filas «en emisión» por tema, «Para volver a ver», recientes, favoritos, una fila por categoría), **Temas** (Deportes, Noticias, Películas…: en emisión, esta noche, todos los canales; pulsación larga para cambiar el tema de un canal) y **Guía TV**.
- **Guía TV**: una **cuadrícula** como en Mac: el día como línea de tiempo horizontal, una fila por canal, **columna de canales** y **horas siempre visibles**, marcador rojo de «ahora», programa actual en naranja. Arrastre en ambas direcciones, **pellizque para hacer zoom** en la escala de tiempo (o Menú > Escala de tiempo). Elija el día (hasta 14 días pasados según Ajustes > Replay, y 3 por delante) y pulse una hora para saltar a ella. Pulse un programa para ver su página (**Ver en directo**, **Replay**, **Recordármelo**, favorito); la pulsación larga ofrece las mismas acciones. El menú filtra por **favoritos, recientes, tema o categoría**, y vuelve a la vista de **Franjas** (una fila por canal a la hora elegida).
- **Replay**: en los canales marcados con ↺, **vuelva a ver** un programa del archivo del proveedor (detalles del programa, o pulsación larga en un canal > Volver a ver). En el reproductor, **Volver al directo**; cuando termina un replay, vuelve al directo automáticamente (ajustable). Ajustes > Replay: días pasados, corrección horaria si un replay empieza a una hora equivocada.
- **Películas** y **Series**: visualización **Cine** (banner «destacado» con desplazamiento, continuar, recientes, favoritos, una fila por categoría —primero la **categoría de inicio** (Ajustes > Organización)—, filtro por país como en Mac) o **Cuadrícula** (todo el catálogo); búsqueda, página de detalles con sinopsis, reanudar donde lo dejó, temporadas y episodios. Ajustes > Visualización Cine: contenido y velocidad del banner.
- **Reproductor**: pulse para mostrar los controles. **Gestos**: doble toque a la izquierda = −10 s, a la derecha = +30 s, en el centro = pausa; **deslizar verticalmente** a la derecha = volumen, a la izquierda = brillo; **deslizar horizontalmente** = avanzar o retroceder en una película (vista previa del tiempo), o **cambiar de canal** en directo. El altavoz de la parte inferior ajusta el **volumen** y **silencia / reactiva el sonido**; la insignia de arriba a la derecha (color de recepción, HD / 4K) abre la **información de la emisión**: resolución, tasa de bits, imágenes por segundo, imágenes perdidas, interrupciones. Para una película o un episodio, la barra muestra el tiempo transcurrido, el **tiempo restante** y la **hora de fin**. En directo, el **programa actual** (barra de progreso) y el siguiente se muestran bajo el nombre del canal, y los botones |◀ ▶| van al canal anterior / siguiente de la categoría. El botón ⋯ ofrece la **velocidad de reproducción** (0,5× a 2×), el **formato de imagen** (ajustar, llenar la pantalla, 16:9, 4:3), el **último canal** visto y, para una serie, la **lista de episodios**; el botón **Siguiente** inicia el episodio siguiente, y los episodios **se reproducen uno tras otro** (Ajustes > App > Reproducción).
- **Mis vídeos**: el botón de arriba a la derecha **ordena** (nombre A→Z / Z→A, fecha, tamaño, duración), **agrupa** (menú Agrupar por: fuente, categoría / carpeta / álbum, tipo, año o mes de adición, **con varios criterios a la vez**, p. ej. Fuente y después Categoría, con secciones plegables; el orden se aplica dentro de cada sección) y **filtra** (tipo, visionado: sin ver / en curso / visto / favoritos, fuente). Ordenar por tamaño mide los archivos la primera vez; los vídeos de tamaño desconocido (servidores) van al final. Sus elecciones se recuerdan.
- **Categorías**: Ajustes > Gestionar las categorías: **Deseleccionar todo / Seleccionar todo** arriba de la lista (práctico para conservar solo unas pocas categorías), orden (arrastrar), ocultar, renombrar, ocultar por palabra clave (p. ej. PAKISTAN), ordenar A→Z, restablecer; Países e idiomas para la visualización Cine. Para reordenar los **canales** de una categoría: Directo en vista de lista, elija la categoría, menú de arriba a la derecha > «Reordenar los canales…».
- **Editar un canal** (pulsación larga): nombre, número, logotipo (dirección web o foto), tema, canal de la guía de TV asociado cuando la guía es incorrecta.
- **Apariencia**: tema, color de acento, tamaño de los pósteres, densidad de lista, visualización predeterminada para Directo, Películas y Series.
- **Inicio**: pestaña mostrada al iniciar, y página de inicio de Directo, Películas y Series (todo, favoritos, recientes, última vista o una categoría).
- **Editar una fuente**: Ajustes > Fuentes, pulse una fuente (o deslícela > Editar) para cambiar su nombre, dirección, credenciales (contraseña o token vacío = se conserva), guía de TV o carpetas, y probar la conexión de una cuenta Xtream.
- **Sincronización con iCloud**: Ajustes > **iCloud**. Encuentre fuentes, favoritos, reanudación de la reproducción… en su iPhone, iPad y Mac mediante una carpeta de iCloud Drive. Véase la página [Sincronizar con iCloud](#icloud).
- **Vídeos locales (galería)**: Ajustes > **Añadir los vídeos de la galería** (o Añadir una fuente > Galería del iPhone para **elegir álbumes**: Cámara, Capturas de pantalla…). Los vídeos aparecen en Películas, en **Mis vídeos**, con su miniatura, ordenados por fecha de captura; una película bien nombrada (título exacto) obtiene su póster y su sinopsis de TMDB. iOS pide acceso a sus fotos: si solo permite una **selección**, solo aparecen esos vídeos (Ajustes > Vídeos locales > Elegir más vídeos…). Un vídeo guardado solo en iCloud se descarga antes de reproducirse. No se copia ni se envía nada a otro sitio. Ajuste: actualizar al abrir la aplicación.
- **Páginas TMDB**: con una clave TMDB gratuita (Ajustes > Fichas de películas y series), la página de una película o serie muestra el póster en HD, la sinopsis traducida, los géneros, la valoración, el reparto con fotos y el tráiler, y el banner destacado ofrece **las tendencias de la semana** que se encuentran en su catálogo. ¿Una página es errónea? En la página, **Corregir la ficha…**: pegue el número o la dirección de la página de themoviedb.org, busque por título o escriba a mano el título, el año, el póster y la sinopsis. **Eliminar la corrección** vuelve a la página automática; la lista de correcciones está en Ajustes.
- **Varias suscripciones**: Ajustes > Suscripciones para mostrar una sola fuente sin desactivar la otra, fusionar duplicados entre cuentas y **Diagnóstico** de una fuente (deslícela hacia la izquierda).
- **Grabar la TV en directo**: durante un canal en directo, el botón redondo rojo del reproductor lo graba (detención automática ajustable). Los archivos .ts están en la **app Archivos > En mi iPhone > Kastideo > Enregistrements**; reprodúzcalos en Kastideo o VLC, compártalos o elimínelos (deslizando). No es posible programar grabaciones en iPhone (la aplicación no puede activarse sola): use las alertas o el Mac.
- **Descargar** una película o episodio: el botón ↓ de su página (o «Descargar la temporada»). Las descargas continúan con la aplicación cerrada; pause, reanude y elimine en **Grabaciones** (icono de bandeja arriba a la derecha, o Ajustes). Los archivos van a Archivos > Kastideo > Téléchargements. Las descargas se hacen **de una en una** (una temporada va episodio tras episodio, los demás muestran «En espera»). Muchos proveedores permiten una sola conexión: una descarga puede interrumpir la reproducción en curso.
- **Directo en diferido**: pause el canal en directo, sigue almacenándose. Retroceda 10 s, avance 30 s, arrastre la línea de tiempo, acelere (×1,25 a ×2) y pulse **Volver al directo**. Duración máxima y velocidad: Ajustes > Directo en diferido.
- **Alertas de programas** (Ajustes): por palabra clave, por tema en sus canales favoritos, o «Avisarme al inicio» en la página de un programa. Son notificaciones del iPhone, recibidas incluso con la aplicación cerrada; pulse una para abrir el canal. Permita las notificaciones cuando iOS lo pida.
- **Mis vídeos**: Ajustes > Añadir una fuente > **Jellyfin, Emby, Plex** o **Carpetas de vídeo** (iPhone, iCloud Drive, unidad USB, NAS añadido en Archivos). En Películas y Series, el botón de arriba a la derecha elige **Todo / IPTV / Mis vídeos**.
- **YouTube** (pestaña YouTube, o el mosaico de Inicio): siga canales (pegue su enlace o @identificador en el campo de búsqueda, sin clave ni cuenta), pegue el enlace de un vídeo o lista de reproducción para reproducirlo, **busque** con su propia clave de API de Google gratuita (Ajustes > YouTube, pasos incluidos), reserve vídeos **para más tarde** (pulsación larga), añada favoritos, encuentre su **historial** y la posición de reanudación (barra roja en la miniatura). Importe sus suscripciones desde una exportación de **Google Takeout** (subscriptions.csv). La reproducción usa el reproductor oficial de YouTube en «modo de privacidad mejorada»; no es un bloqueador de anuncios. Iniciar un vídeo detiene la reproducción IPTV.
- **MultiVista**: varios canales a la vez (2 a 4 pantallas), como en Mac. Solo se ofrece si sus fuentes permiten al menos dos emisiones simultáneas: indique el número de conexiones de cada suscripción en **Ajustes > MultiVista** (1 para la mayoría; una lista pública permite 4). Ábrala con el botón ▦ en **Directo** o en el reproductor (se añade el canal actual). Cada pantalla está reservada a una fuente; elija los canales, la disposición (lado a lado, apiladas, cuadrícula, **una grande + miniaturas arrastrables**) y el número de pantallas desde el menú superior. Pulse una pantalla para darle el sonido, doble toque en una miniatura para hacerla grande, pulsación larga para cambiar de canal, de fuente o quitar la pantalla. Abrir MultiVista detiene la reproducción principal (salvo que haya una grabación en curso).
- **Reproductor a pantalla completa**: pulse la imagen para mostrar los controles, arrastre la barra para moverse, elija la pista de audio y los subtítulos. Ciérrelo con la flecha: la reproducción continúa, con un **minirreproductor** sobre la barra de pestañas. El sonido continúa con la pantalla bloqueada.
- **AirPlay**: el botón del reproductor envía el sonido a un Apple TV o HomePod; para el vídeo, use la duplicación de pantalla de iOS.
- Mismo motor de reproducción (VLC) y mismos ajustes de búfer que en Mac; relé de emisión para los proveedores que rechazan las conexiones directas.

**Aún no en iPhone / iPad**: imagen en imagen (no disponible con el motor de reproducción actual). Una versión para **Apple TV** está prevista para más adelante.

Si la reproducción falla: **Ajustes > Acerca de > Compartir el registro de reproducción**.
## Sincronizar con iCloud (iPhone, iPad, Mac) {#icloud}

Kastideo puede mantener **sus dispositivos Apple idénticos**: iPhone, iPad y Mac comparten sus fuentes, favoritos, historial, categorías, ajustes de visualización, **reanudación de la reproducción**, fichas de detalles corregidas y, opcionalmente, **contraseñas**. La sincronización pasa por **una carpeta de su iCloud Drive**: Kastideo deposita allí pequeños archivos.

**Configuración (en cada dispositivo).**

1. En iCloud Drive, cree una carpeta, por ejemplo **Kastideo** (una sola vez). Compruebe que iCloud Drive está activado en todos los dispositivos.
2. Abra Kastideo > Ajustes > **iCloud** y active **Sincronizar con iCloud Drive**.
3. Pulse **Carpeta de sincronización** y elija **la misma carpeta**.
4. Elija qué sincronizar.
5. Si sincroniza las contraseñas o la clave TMDB, introduzca la **frase de contraseña** (la misma en todos los dispositivos) y después **Guardar la frase de contraseña**.

**Conviene saber.**

- Prevalece el cambio más reciente. En la primera sincronización, las listas (fuentes, favoritos, historial) se fusionan.
- Las contraseñas se **cifran** con su frase de contraseña antes de almacenarse: sin ella, nadie puede leerlas. Anótela: no se puede recuperar.
- Las carpetas de vídeo, los archivos M3U y la galería siguen siendo propios de cada dispositivo. Los ajustes de visualización específicos de Mac y de iPhone se conservan por separado.
- La sincronización se ejecuta cada 30 segundos, al volver a la aplicación y al pasar a segundo plano; **Sincronizar ahora** la fuerza. En Mac, un pequeño icono de nube en la parte inferior de la barra lateral muestra el estado.
- «Borrar los archivos de sincronización» elimina los archivos de la carpeta para todos sus dispositivos (sus datos locales se conservan).
- Windows, Linux y Android no están incluidos: use la exportación / importación de la configuración.

## Novedades {#nouveautes}

Tras cada actualización, la ventana **Novedades** resume los cambios de la versión instalada.

<!--mac-->
Puede volver a abrirla con **Ayuda > Novedades de esta versión** o haciendo clic en el número de versión abajo a la derecha del Inicio, y consultar allí versiones anteriores.
<!--/mac-->
<!--pc-->
Puede volver a abrirla haciendo clic en el número de versión abajo a la derecha del Inicio, y consultar allí versiones anteriores.
<!--/pc-->

El historial completo también se publica en la página de [GitHub Releases](https://github.com/jihemezes/kastideo/releases).

# Solución de problemas

## Solución de problemas {#depannage}

<!--mac-->
- **Un canal no tiene sonido**: Kastideo lo detecta en pocos segundos y lo repara solo: si el reloj de la emisión está desfasado (se descarta el sonido, «buffer too late» en el registro), el canal se vuelve a abrir sincronizado con el sonido y la imagen, y Kastideo lo recuerda; si no, reinicia la pista de audio o prueba la siguiente. Si un icono naranja 🔇 permanece junto al indicador de estado, el proveedor envía una emisión sin sonido o una pista ilegible: pruebe otra versión del canal (HD, SD…) o elija otra pista de audio en el panel de información (⌘I). El registro de reproducción (líneas «Son :») muestra el formato recibido.

- **«El proveedor rechaza este canal (HTTP 403)»**: el propio proveedor bloquea este canal (fuera de servicio o no incluido en su suscripción). Kastideo no insiste; pruebe otra versión (HD, SD…) o más tarde.
- **Imagen congelada, «Emisión defectuosa en el proveedor»**: el reloj de la emisión es incoherente. Kastideo vuelve a abrir el canal una vez, sincronizado con el sonido y la imagen; si no basta, pasa a **solo imagen** (sin sonido) para que la imagen deje de congelarse, y lo recuerda. Clic derecho en el canal > **Solo imagen (sin sonido)** para activarlo o desactivarlo a mano. Ajustes > General > Reproducción > **Restablecer** cancela estas reparaciones recordadas.
- **Relé de emisión** (Ajustes > General > Reproducción, activado por defecto): Kastideo abre él mismo la conexión con el proveedor y se la pasa al motor VLC, como Piboard, de modo que nunca hay dos a la vez. El registro de reproducción muestra entonces líneas «Relais :» con la respuesta exacta del proveedor (p. ej. «HTTP 200 en 0,35 s»).
- **Cambio de canal lento o rechazado («HTTP 404», «403», «401» o «520» en el registro de reproducción)**: con una suscripción de una sola conexión, el proveedor tarda un momento en liberar el canal anterior. Kastideo espera 1,5 s antes de abrir el nuevo canal y lo reintenta una vez si se rechaza («Attente…» y «nouvel essai» en el registro). Si los rechazos persisten, espere un minuto y vuelva a intentarlo.

Kastideo se identifica ante los servidores como el reproductor **VLC**: muchos proveedores IPTV solo responden a los reproductores que reconocen.

- **«El servidor no ha respondido a tiempo»**: el servidor está sobrecargado o no disponible. Vuelva a intentarlo más tarde; si su dirección tiene la forma `get.php?username=…`, compruebe que se ha convertido a Xtream Codes (tipo mostrado en los ajustes de las fuentes).

- **«Usuario o contraseña rechazados»**: compruebe sus credenciales con **Probar la conexión**.
- **«Cuenta no activa»**: la suscripción ha caducado o está suspendida en su proveedor.
- **Ningún programa en la guía**: el canal no tiene identificador de guía de TV, o la guía de su fuente no contiene ninguno para él.
- **«App Transport Security»**: este mensaje apareció en las versiones 0.1.0 y 0.2.0 con fuentes http://. Está corregido desde la versión 0.2.1.
- **No se puede reproducir**: el servidor no ha proporcionado la emisión. Compruebe que ningún otro dispositivo usa su suscripción (solo se permite una conexión) y haga clic en **Reintentar**. Pruebe también el búfer **Estable**.
<!--/mac-->

<!--pc-->
- **Un canal no arranca**: abra el **Registro** (Ctrl+Alt+L, tema *Reproducción y relé*). Las líneas «Relais :» dan la respuesta exacta del proveedor (p. ej. «HTTP 200 en 0,35 s» o «HTTP 403»).
- **La actualización no se instala**: el registro de reproducción (Ctrl+Alt+L) indica el motivo. Paquete .deb: si no aparece la ventana de contraseña, el comando que hay que escribir en un terminal se muestra en la ventana de actualización. Siempre puede descargar la nueva versión desde la página de versiones de GitHub.
- **MultiVista: un bloque se queda negro**: el proveedor rechaza una conexión adicional. Compruebe el número de conexiones de su suscripción (Ajustes > General > Reproducción > Detectar).
- **Ninguna notificación**: compruebe Ajustes > General > Notificaciones y después los ajustes de notificaciones de Windows (Configuración > Sistema > Notificaciones) o de su escritorio Linux. En Linux se necesita el paquete libnotify (instalado por el .deb, incluido en el AppImage).
- **Grabación vacía**: el proveedor no ha enviado nada (canal rechazado, conexión ya usada por otro dispositivo). Las líneas «Enregistrement» del registro dan la respuesta del proveedor (p. ej. «HTTP 403») e indican si no llegaron datos tras 30 s.
- **El diferido no retrocede más**: su profundidad depende del espacio temporal en disco; sin caché en disco (algunas versiones de libmpv en Linux), se limita a 512 MB en memoria.
- **Detalles en otro idioma**: algunos proveedores solo tienen un idioma. Con una **clave TMDB**, las sinopsis, géneros y episodios proceden de TMDB en su idioma.
- **Ventana única**: si se inicia estando ya en ejecución, Kastideo se limita a traer la ventana existente al primer plano.
- **Sin imagen en Linux**: compruebe que el paquete **libmpv** está instalado (el .deb lo instala; el AppImage lo incluye).
- **VPN**: una VPN activa puede impedir que el proveedor sirva las emisiones.
- **Ningún programa en la guía**: Ajustes > Fuentes muestra el estado de la guía de cada fuente; la guía de respaldo completa los canales franceses habituales.
- **Contraseñas en Linux**: sin un llavero (GNOME Keyring o KWallet), Kastideo guarda las contraseñas en sus preferencias y lo indica en el registro.
<!--/pc-->

## La ventana está fuera de la pantalla (Windows y Linux) {#fenetre-hors-ecran}

Con varias pantallas, una ventana podía abrirse medio fuera de la pantalla sin una barra de título accesible. Desde la versión 1.12.1, Kastideo **recuerda la posición de su ventana** y, al iniciar, comprueba que su barra de título es visible en una pantalla. Si no lo es (pantalla desconectada, resolución o escala modificadas), la ventana se **recentra en la pantalla principal**.

Si una ventana sigue fuera de alcance: en Windows, pulse **Alt + Espacio** y después **M** (Mover), y luego las teclas de flecha; o cierre Kastideo y vuelva a iniciarlo.

# Acerca de

## Aviso legal {#avertissement}

Gracias por usar Kastideo. Kastideo es un reproductor multimedia: reproduce listas de reproducción (M3U), cuentas IPTV (Xtream Codes), sus propios servidores (Jellyfin, Emby, Plex), los vídeos de sus unidades y YouTube.

- **No proporciona contenido.** Kastideo no proporciona, aloja ni vende ningún canal, película, lista de reproducción ni suscripción.
- **Sin afiliación.** Kastideo no está afiliado a ningún proveedor de contenidos o de suscripciones IPTV, ni a YouTube, Google, TMDB, Plex, Jellyfin, Emby, Apple o Microsoft. Las marcas mencionadas pertenecen a sus respectivos propietarios. Este producto utiliza la API de TMDB, pero no está respaldado ni certificado por TMDB.
- **Su propio contenido.** Usted debe aportar sus propias fuentes y contenidos. Es el único responsable de comprobar que son legales y de que dispone de todos los derechos necesarios para verlos, grabarlos, descargarlos y retransmitirlos.
- **Derechos de autor.** Kastideo no fomenta la retransmisión de material protegido por derechos de autor sin el permiso del titular de los derechos. Las grabaciones, descargas y envíos a un televisor son solo para uso privado, dentro de los límites de la ley de su país.
- **Responsabilidad.** El autor de Kastideo no es responsable del uso que usted haga del programa, ni del contenido, la disponibilidad o la legalidad de los servicios de terceros a los que lo conecte. Kastideo se proporciona de forma gratuita, «tal cual», sin garantía.
- **Sus datos.** Sus credenciales se conservan en su dispositivo y solo se envían a los servicios que usted configure.

Al hacer clic en «Entiendo y acepto», confirma que ha leído y acepta estas condiciones. En caso contrario, cierre la aplicación.

Este aviso aparece en el primer inicio y después de cada actualización. Puede volver a leerlo en cualquier momento en <!--mac-->**Ajustes (⌘,) > Acerca de**<!--/mac--><!--pc-->**Ajustes (Ctrl+,) > Acerca de**<!--/pc-->.

## Apoyar Kastideo {#soutenir}

<!--mac-->
Kastideo es **gratuito**. Si le gusta la aplicación, puede animar su desarrollo invitándome a un café en [Ko-fi](https://ko-fi.com/jihemezes): es totalmente opcional.

El botón **Invítame a un café** aparece discretamente en la pantalla de inicio y en la ventana Novedades, así como en **Ajustes > Acerca de** y en **Ayuda > Apoyar Kastideo (Ko-fi)**. Para ocultar los botones de la pantalla de inicio y de Novedades, marque **Ocultar los botones «Invítame a un café»** en **Ajustes > Acerca de**.
<!--/mac-->

<!--pc-->
Kastideo es **gratuito**. Si le gusta la aplicación, puede animar su desarrollo invitándome a un café en [Ko-fi](https://ko-fi.com/jihemezes): es totalmente opcional.

El botón **Invítame a un café** aparece discretamente en la pantalla de inicio y en la ventana Novedades, así como en **Ajustes > Acerca de**. Para ocultar los botones de la pantalla de inicio y de Novedades, marque **Ocultar los botones «Invítame a un café»** en **Ajustes > Acerca de**.
<!--/pc-->

## Privacidad {#confidentialite}

<!--mac-->
Kastideo se ejecuta en el entorno aislado (sandbox) de macOS. Solo accede a la red y a los archivos que usted elige. Sus contraseñas permanecen en el llavero. No se envían datos a ningún sitio que no sean sus propias fuentes.
<!--/mac-->

<!--pc-->
Kastideo no recopila ningún dato. Solo contacta con sus proveedores IPTV, las guías de TV que haya elegido, GitHub para las actualizaciones y, si ha introducido una clave, TMDB. Sus ajustes, favoritos y contraseñas permanecen en su ordenador.
<!--/pc-->

## Licencias {#licences}

<!--mac-->
Kastideo utiliza **VLCKit** (el motor de VLC, © VideoLAN, licencia LGPL 2.1 o posterior, https://www.videolan.org/vlc/libvlc.html) y **Sparkle** (licencia MIT, https://sparkle-project.org). VLCKit está integrado como una biblioteca dinámica sin modificar.
<!--/mac-->
