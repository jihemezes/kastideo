# Primeiros passos

## Boas-vindas {#tv-bienvenue}

O Kastideo é um **player**: não fornece nenhum canal, filme ou assinatura. Você adiciona a sua própria fonte e depois tudo se controla com o controle remoto.

A tela inicial mostra grandes blocos **Ao vivo**, **Filmes** e **Séries** (e **Meus vídeos** se você tiver um servidor Jellyfin, Emby ou Plex), depois botões: **Continuar**, **Recentes**, **Favoritos**, **Guia de TV**, **Buscar**, **Ajustes** e **Ajuda**. As mesmas seções estão na barra superior.

> Esta ajuda é específica para a Apple TV. O guia completo do Kastideo (Mac, iPhone, iPad, Windows, Linux, Android) pode ser consultado no aplicativo nesses dispositivos.

## Adicionar uma fonte {#tv-sources}

Digitar um endereço e uma senha com o controle remoto é incômodo: o Kastideo oferece três soluções. Para experimentar sem assinatura, selecione **Experimentar a demo**: o Kastideo adiciona alguns vídeos livres de direitos.

1. **A partir de um celular (código QR)**: **Ajustes > Fontes > Adicionar a partir de um celular**. Escaneie o código QR com um celular ou abra o endereço mostrado num computador da mesma rede Wi-Fi, preencha o formulário e digite o **código de 4 dígitos** exibido na tela. Esta tela deve permanecer aberta durante a digitação.
2. **A partir de um iPhone ou iPad**: no Kastideo do iPhone, **Ajustes > Backup > Enviar para a Apple TV** transmite de uma vez suas fontes, favoritos e ajustes (mesma rede Wi-Fi, mesmo código de 4 dígitos).
3. **Com o teclado**: **Ajustes > Fontes > Adicionar uma fonte com o teclado…**

Tipos de fontes: assinatura **Xtream Codes**, lista **M3U** (endereço) e servidores **Jellyfin, Emby, Plex** (seção **Meus vídeos**). A sincronização via iCloud não existe na Apple TV.

Para editar, atualizar, excluir ou **mudar a ordem** de uma fonte (Subir / Descer: as do topo aparecem primeiro): **Ajustes > Fontes** e depois a fonte.

# Usar o Kastideo

## O controle remoto {#tv-telecommande}

- **Superfície touch / setas**: mover-se; **clique**: confirmar.
- **Botão Menu (voltar)**: voltar; no player, interrompe a reprodução.
- **Reproduzir / Pausar**: pausa ou retoma.
- **Toque longo em um pôster ou canal**: abre um pequeno menu (adicionar ou remover dos favoritos). Em um episódio: marcar como visto ou não visto.
- **No player**: ↑ / ↓ trocam de canal ao vivo, ← volta 10 s e → avança 30 s em um filme ou episódio, um **clique** abre as opções.

## Ao vivo e zapping {#tv-direct}

Abra **Ao vivo**: os canais são organizados por categoria (botão **Categoria**) e o botão de exibição escolhe a interface **Clássica**, **Cinema** ou **TV**. A interface **TV** funciona como uma televisão: zapping por número e último canal iniciado ao abrir (ajustável).

Durante a reprodução, ↑ / ↓ trocam de canal. Conforme **Ajustes > Reprodução > Zapping**, um clique confirma a escolha na lista (**com confirmação**) ou a troca é **imediata**. Nas opções do player: **Último canal** (voltar ao anterior) e **Ir ao canal nº…**.

## Guia de TV e replay {#tv-guide}

A aba **Guia de TV** mostra uma grade de 3 horas. Clique em um programa: **Assistir ao canal**, ou **Rever este programa** quando o provedor guarda as transmissões passadas (replay). O ajuste **Ajustes > Guia de TV > Ao abrir o guia** escolhe entre **Agora** e **Última posição**.

> O guia vem do seu provedor; um guia de reserva é usado se ele estiver incompleto.

## Filmes e séries {#tv-films}

**Filmes** e **Séries** aparecem em grade **Clássica** ou em **Cinema** (banner e fileiras por categoria). Clique em um pôster para abrir a página: sinopse e elenco (com uma chave TMDB) e depois **Reproduzir**. Em uma série, escolha a temporada e o episódio; o episódio seguinte pode continuar automaticamente.

A **busca** pesquisa canais, filmes e séries.

## O player {#tv-lecteur}

Um **clique** durante a reprodução abre as **Opções**:

- adicionar ou remover dos **favoritos**;
- **Timer de desligamento**: interrompe a reprodução após alguns minutos;
- **Faixas de áudio** e **Legendas**;
- **Velocidade de reprodução** (filmes e episódios);
- ao vivo: **Último canal** e **Ir ao canal nº**;
- em uma série: **Próximo episódio**.

Um banner de informações aparece por alguns segundos (canal, programa em andamento).

## Favoritos, continuar e «visto» {#tv-favoris}

- **Favoritos**: toque longo em um pôster ou canal, ou as **Opções** do player. A lista está no botão **Favoritos** da tela inicial.
- **Continuar**: filmes e episódios iniciados retomam de onde você parou (ajustável em **Ajustes > Reprodução**). Com Jellyfin, Emby e Plex, a retomada é compartilhada com o servidor.
- **Visto**: um episódio visto fica marcado; toque longo para mudar.
- **Recentes**: os últimos conteúdos assistidos.
- **Apagar**: Definições > **Históricos** apaga os **Recentes** e os **Vistos e a retoma**, um a um ou com **Apagar tudo** (com confirmação). Os favoritos e as fontes não são afetados.

# Ajustes

## Idioma e exibição {#tv-reglages}

- **Idioma**: **Ajustes > Idioma do aplicativo**. «Sistema» segue o idioma da Apple TV; você pode escolher francês, inglês, espanhol, alemão, italiano, português (Portugal) ou português (Brasil). A mudança é imediata.
- **Página inicial**: para Ao vivo, Filmes e Séries, a primeira categoria, os favoritos, os recentes, a última consultada ou uma categoria específica.
- **Exibição**: Clássica, Cinema ou TV, separadamente para ao vivo, filmes e séries.
- **Categorias**: mostrar ou ocultar categorias (**Ocultar tudo** e marque só as desejadas); canais adultos (ocultos por padrão). Recalcular a exibição pode levar alguns segundos: um banner avisa.
- **Reprodução**: zapping, **Buffer** (Rápido, Equilibrado, Estável: escolha Estável se a imagem engasgar), retomada de filmes e decodificação por software.

## Pôsteres e sinopses (TMDB) {#tv-tmdb}

Pôsteres, sinopses, elenco e tendências vêm do **TMDB**, um serviço gratuito. É preciso uma **chave de API** pessoal: crie uma conta gratuita em themoviedb.org, abra **Ajustes > API** e digite a chave em **Ajustes > TMDB**. Sem chave, o Kastideo funciona com as informações do seu provedor.

# Solução de problemas

## Se um canal não iniciar {#tv-depannage}

1. Aguarde alguns segundos: alguns canais demoram a iniciar.
2. Tente outro canal e depois volte.
3. Sua assinatura pode permitir apenas **uma conexão por vez**: feche o Kastideo nos seus outros dispositivos.
4. Desative qualquer **VPN** da rede.
5. Imagem congelada ou engasgando: **Ajustes > Reprodução > Sempre decodificar por software**, ou **Buffer: Estável**.
6. Conteúdos vazios: **Ajustes > Fontes > Atualizar tudo**.

Para entender um problema específico, o **Registro de reprodução** pode ser consultado no Mac, iPhone ou iPad.

## Aviso legal e privacidade {#tv-legal}

O Kastideo não fornece, hospeda nem vende nenhum conteúdo: você é responsável pela legalidade das suas fontes. O aviso completo está em **Ajustes > Sobre > Aviso legal**.

O Kastideo não coleta nenhum dado: suas fontes e ajustes ficam na Apple TV, e as credenciais só são enviadas aos serviços que você configurar (seu provedor, seus servidores, o TMDB se você informar uma chave). Política completa: https://github.com/jihemezes/kastideo/blob/main/docs/PRIVACY.md
