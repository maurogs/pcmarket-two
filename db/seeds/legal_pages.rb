# frozen_string_literal: true

# Public legal documents. Spanish is authoritative; the other five locales are
# translations for Spain. France, the United Kingdom, Germany, Italy and
# Portugal are seeded as drafts in their own language plus English, ready for a
# lawyer to review and an admin to publish.
#
# Every row keeps review_required = true: the admin screen shows the warning
# and the public page never renders it.

legal_titles = {
  "es" => {
    terms: "Condiciones del servicio",
    privacy: "Política de privacidad",
    cookies: "Política de cookies",
    legal_notice: "Aviso legal",
    returns: "Política de devoluciones",
    seller_terms: "Condiciones para vendedores",
    buyer_protection: "Protección al comprador",
    dsa_transparency: "Transparencia DSA",
    prohibited_items: "Artículos prohibidos",
    fees: "Tarifas",
    accessibility: "Declaración de accesibilidad"
  },
  "en" => {
    terms: "Terms of service",
    privacy: "Privacy policy",
    cookies: "Cookie policy",
    legal_notice: "Legal notice",
    returns: "Returns policy",
    seller_terms: "Seller terms",
    buyer_protection: "Buyer protection",
    dsa_transparency: "DSA transparency",
    prohibited_items: "Prohibited items",
    fees: "Fees",
    accessibility: "Accessibility statement"
  },
  "fr" => {
    terms: "Conditions d'utilisation",
    privacy: "Politique de confidentialité",
    cookies: "Politique de cookies",
    legal_notice: "Mentions légales",
    returns: "Politique de retour",
    seller_terms: "Conditions vendeurs",
    buyer_protection: "Protection de l'acheteur",
    dsa_transparency: "Transparence DSA",
    prohibited_items: "Articles interdits",
    fees: "Tarifs",
    accessibility: "Déclaration d'accessibilité"
  },
  "de" => {
    terms: "Nutzungsbedingungen",
    privacy: "Datenschutzerklärung",
    cookies: "Cookie-Richtlinie",
    legal_notice: "Impressum",
    returns: "Rückgaberichtlinie",
    seller_terms: "Verkäuferbedingungen",
    buyer_protection: "Käuferschutz",
    dsa_transparency: "DSA-Transparenz",
    prohibited_items: "Verbotene Artikel",
    fees: "Gebühren",
    accessibility: "Erklärung zur Barrierefreiheit"
  },
  "it" => {
    terms: "Termini di servizio",
    privacy: "Informativa sulla privacy",
    cookies: "Informativa sui cookie",
    legal_notice: "Note legali",
    returns: "Politica di reso",
    seller_terms: "Condizioni per i venditori",
    buyer_protection: "Protezione dell'acquirente",
    dsa_transparency: "Trasparenza DSA",
    prohibited_items: "Articoli vietati",
    fees: "Tariffe",
    accessibility: "Dichiarazione di accessibilità"
  },
  "pt" => {
    terms: "Termos de serviço",
    privacy: "Política de privacidade",
    cookies: "Política de cookies",
    legal_notice: "Aviso legal",
    returns: "Política de devoluções",
    seller_terms: "Condições para vendedores",
    buyer_protection: "Proteção do comprador",
    dsa_transparency: "Transparência DSA",
    prohibited_items: "Artigos proibidos",
    fees: "Tarifas",
    accessibility: "Declaração de acessibilidade"
  }
}.freeze

legal_documents = {
  "es" => {
    terms: <<~HTML,
      <h2>Qué es PCMarket</h2>
      <p>PCMarket es un mercado en línea que pone en contacto a compradores y vendedores de hardware y accesorios de PC. PCMarket no es el vendedor ni forma parte del contrato de compraventa: actúa como intermediario tecnológico y de pago.</p>
      <h2>Obligaciones de las partes</h2>
      <p>El comprador se compromete a facilitar datos veraces, pagar el precio y revisar el artículo al recibirlo. El vendedor se compromete a describir el artículo con exactitud, acreditar que puede venderlo, enviarlo en el plazo indicado y respetar los derechos del consumidor.</p>
      <h2>Precios, pagos y comisiones</h2>
      <p>Los precios se muestran en euros con los impuestos aplicables. El pago se realiza dentro de la plataforma mediante Stripe y queda retenido hasta que se cumple la protección al comprador. Las comisiones vigentes se publican en la página de tarifas.</p>
      <h2>Artículos prohibidos</h2>
      <p>No se pueden publicar artículos ilegales, robados, falsificados, peligrosos o que infrinjan derechos de terceros. PCMarket puede retirar anuncios y suspender cuentas.</p>
      <h2>Incidencias y resolución de conflictos</h2>
      <p>Las incidencias se gestionan desde el pedido. %{consumer_law} protege a los consumidores. Para cualquier controversia serán competentes %{courts}. %{odr_note}</p>
      <h2>Ley aplicable</h2>
      <p>Estas condiciones se rigen por la legislación de %{country}. %{local_note}</p>
    HTML
    privacy: <<~HTML,
      <h2>Responsable del tratamiento</h2>
      <p>El responsable es %{company}, con domicilio en %{address} y correo %{email}. Los datos de registro figuran en el aviso legal.</p>
      <h2>Datos que tratamos</h2>
      <ul><li>Identificación y contacto: nombre, usuario, correo, teléfono y dirección.</li><li>Actividad: anuncios, mensajes, favoritos, compras y valoraciones.</li><li>Pagos: importes, estado y referencias de Stripe; no almacenamos números de tarjeta.</li><li>Datos técnicos: IP, dispositivo, idioma y cookies.</li></ul>
      <h2>Finalidades y bases jurídicas</h2>
      <p>Tratamos los datos para ejecutar el contrato (cuenta, compraventa y pagos), cumplir obligaciones legales (facturación y prevención del fraude), atender intereses legítimos (seguridad y mejora del servicio) y, con tu consentimiento, enviar comunicaciones comerciales.</p>
      <h2>Conservación y destinatarios</h2>
      <p>Conservamos los datos durante la relación y los plazos legales. Los destinatarios son Stripe (pagos), el proveedor de alojamiento y correo, y las autoridades cuando exista obligación legal. No vendemos datos personales.</p>
      <h2>Transferencias internacionales</h2>
      <p>Si algún proveedor trata datos fuera del EEE, lo hace con garantías adecuadas, como las cláusulas contractuales tipo de la Comisión Europea.</p>
      <h2>Derechos</h2>
      <p>Puedes ejercer acceso, rectificación, supresión, oposición, limitación y portabilidad escribiendo a %{email}. También puedes reclamar ante %{authority}. %{local_note}</p>
      <h2>Cookies</h2>
      <p>El uso de cookies se explica en la <a href="%{cookies_path}">política de cookies</a>.</p>
    HTML
    cookies: <<~HTML,
      <h2>Qué son las cookies</h2>
      <p>Son archivos o almacenamiento local que permiten recordar tu sesión, tus preferencias y, si lo autorizas, medir el uso del sitio. No usamos cookies no esenciales antes de tu consentimiento.</p>
      <h2>Categorías</h2>
      <ul><li>Necesarias: hacen funcionar la web y no se pueden desactivar.</li><li>Preferencias: recuerdan idioma, país y tema.</li><li>Analítica: miden visitas y páginas usadas.</li><li>Marketing: miden campañas y permiten publicidad relevante.</li></ul>
      <h2>Cookies que usamos</h2>
      <table><thead><tr><th>Nombre</th><th>Finalidad</th><th>Duración</th><th>Categoría</th></tr></thead><tbody><tr><td>pcmarket_session</td><td>Sesión y seguridad</td><td>Sesión</td><td>Necesaria</td></tr><tr><td>locale</td><td>Idioma elegido</td><td>1 año</td><td>Preferencias</td></tr><tr><td>country</td><td>País para contenido legal</td><td>1 año</td><td>Preferencias</td></tr><tr><td>cookie_consent</td><td>Guarda tu elección</td><td>6 meses</td><td>Necesaria</td></tr><tr><td>theme (localStorage)</td><td>Tema claro u oscuro</td><td>Persistente</td><td>Preferencias</td></tr><tr><td>__stripe_mid / __stripe_sid</td><td>Prevención del fraude en pagos</td><td>1 año / sesión</td><td>Necesaria</td></tr></tbody></table>
      <h2>Cómo gestionarlas</h2>
      <p>Puedes cambiar tu elección desde «Preferencias de cookies» en el pie de página. También puedes borrar o bloquear cookies en tu navegador, aunque algunas funciones dejarán de funcionar.</p>
    HTML
    legal_notice: <<~HTML,
      <h2>Titular del sitio</h2>
      <p>%{company}, NIF %{tax_id}, domicilio en %{address}, correo %{email}. Datos registrales: %{registry}.</p>
      <h2>Objeto</h2>
      <p>Este sitio presta un servicio de intermediación entre compradores y vendedores de hardware. Se informa conforme a %{company_law} y a la normativa de comercio electrónico aplicable.</p>
      <h2>Propiedad intelectual</h2>
      <p>La marca, el diseño, los textos y el código son titularidad de %{company} o de sus licenciantes. No se permite su reproducción sin autorización, salvo los usos legales.</p>
      <h2>Responsabilidad</h2>
      <p>PCMarket cuida la disponibilidad y seguridad del servicio, pero no responde de los contenidos publicados por los usuarios ni de los acuerdos entre las partes, sin perjuicio de la protección al comprador.</p>
      <h2>Enlaces</h2>
      <p>Los enlaces externos se ofrecen como referencia. No controlamos su contenido ni asumimos responsabilidad por ellos. %{local_note}</p>
    HTML
    returns: <<~HTML,
      <h2>Compras a vendedores profesionales</h2>
      <p>Si compras a un vendedor profesional, %{consumer_law} te reconoce 14 días naturales para desistir, salvo excepciones legales (productos personalizados, precintos de higiene abiertos o contenido digital ya descargado). No necesitas justificar la decisión.</p>
      <h2>Compras entre particulares</h2>
      <p>Entre particulares no existe un derecho legal de desistimiento. Aun así, la protección al comprador cubre artículos que no lleguen, lleguen dañados o no coincidan con la descripción.</p>
      <h2>Garantía legal</h2>
      <p>Los bienes nuevos comprados a profesionales tienen una garantía legal de 3 años; los de segunda mano, de al menos 1 año, desde la entrega. La garantía cubre la falta de conformidad, no el desgaste normal.</p>
      <h2>Cómo solicitar una devolución</h2>
      <p>Abre una incidencia desde el pedido o escríbenos a %{email} antes de que termine el plazo. El reembolso se realiza al mismo método de pago en un plazo máximo de 14 días desde la aceptación.</p>
      <h2>Formulario de desistimiento</h2>
      <p>A la atención de %{company}, %{address}, %{email}: «Por la presente comunico que desisto del contrato de compraventa del siguiente bien: [DESCRIPCIÓN], pedido el [FECHA] y recibido el [FECHA]. Nombre: [NOMBRE]. Domicilio: [DOMICILIO]. Fecha: [FECHA].»</p>
    HTML
    seller_terms: <<~HTML,
      <h2>Requisitos para vender</h2>
      <p>Debes ser mayor de edad, tener una cuenta confirmada y una tienda con datos veraces. Los vendedores profesionales deben indicar su identidad fiscal y cumplir las obligaciones de información al consumidor.</p>
      <h2>Publicación de anuncios</h2>
      <p>Los anuncios deben describir el producto real, su estado y los accesorios incluidos. Solo puedes vender bienes de tu propiedad o que estés autorizado a vender. Las fotos deben ser propias.</p>
      <h2>Precios, impuestos y envíos</h2>
      <p>Los precios deben incluir los impuestos aplicables. El vendedor es responsable de emitir factura cuando corresponda, de elegir un transporte adecuado y de entregar en el plazo indicado.</p>
      <h2>Pagos y comisiones</h2>
      <p>Los pagos se reciben a través de la plataforma. Las comisiones vigentes se publican en la página de tarifas. La falta de pago de una comisión puede limitar la cuenta.</p>
      <h2>Suspensión y responsabilidad</h2>
      <p>PCMarket puede retirar anuncios o suspender cuentas que incumplan estas condiciones. El vendedor responde de sus anuncios, ventas, impuestos y del cumplimiento de los derechos del consumidor.</p>
    HTML
    buyer_protection: <<~HTML,
      <h2>Qué cubre</h2>
      <p>La protección cubre compras pagadas dentro de PCMarket cuando el artículo no llega, llega dañado, es distinto de lo descrito, es falsificado o el vendedor cancela después del pago.</p>
      <h2>Qué no cubre</h2>
      <p>No cubre pagos fuera de la plataforma, artículos prohibidos, daños no comunicados en plazo, desistimientos entre particulares ni el desgaste normal del producto.</p>
      <h2>Cómo funciona</h2>
      <p>Retenemos el pago, el vendedor envía con seguimiento y tú inspeccionas el artículo durante %{days} días. Si hay un problema, abre una incidencia antes de que termine el plazo.</p>
      <h2>Resolución y reembolsos</h2>
      <p>Revisamos la incidencia y solicitamos información a ambas partes. Si se acepta, reembolsamos al método de pago original y podemos recuperar el importe del vendedor. Las decisiones se comunican con una exposición de motivos.</p>
      <h2>Límites</h2>
      <p>La protección es un servicio de la plataforma y no sustituye los derechos legales que te reconozca %{consumer_law}.</p>
    HTML
    dsa_transparency: <<~HTML,
      <h2>Punto de contacto</h2>
      <p>Para comunicaciones sobre el Reglamento (UE) 2022/2065 (DSA) puedes escribir a %{email}. Atendemos en español y en inglés.</p>
      <h2>Notificación y acción</h2>
      <p>Cualquier persona puede denunciar contenidos presuntamente ilegales desde el botón de denuncia. Confirmamos la recepción, revisamos la denuncia y comunicamos la decisión.</p>
      <h2>Exposición de motivos</h2>
      <p>Cuando retiramos contenido o suspendemos una cuenta, informamos al afectado del motivo, del alcance de la medida y de cómo puede recurrirla.</p>
      <h2>Trazabilidad de comerciantes</h2>
      <p>Los vendedores profesionales deben facilitar su identidad, datos fiscales y contacto. Estos datos se muestran en el anuncio cuando la ley lo exige.</p>
      <h2>Resolución de litigios</h2>
      <p>Las partes pueden acudir a los organismos de resolución alternativa de litigios y a los tribunales. %{odr_note}</p>
      <h2>Transparencia</h2>
      <p>Publicamos información agregada sobre denuncias recibidas, medidas adoptadas y tiempos de respuesta en nuestras comunicaciones periódicas. %{dsa_note}</p>
    HTML
    prohibited_items: <<~HTML,
      <h2>Artículos prohibidos</h2>
      <p>No se pueden publicar productos ilegales, robados, falsificados o que infrinjan derechos de propiedad intelectual. Tampoco se permiten artículos peligrosos o regulados sin autorización.</p>
      <h2>Lista orientativa</h2>
      <ul><li>Armas, munición y réplicas prohibidas.</li><li>Drogas, sustancias controladas y precursores.</li><li>Material de abuso infantil o contenido ilegal.</li><li>Datos personales, cuentas y credenciales.</li><li>Software malicioso, licencias ilegales y herramientas de fraude.</li><li>Baterías dañadas o componentes con riesgo eléctrico.</li><li>Productos retirados por seguridad o objeto de recall.</li><li>Bienes robados o de procedencia no acreditada.</li></ul>
      <h2>Consecuencias</h2>
      <p>Retiramos los anuncios, podemos suspender la cuenta y, cuando proceda, informamos a las autoridades. Si dudas sobre un artículo, pregúntanos antes de publicarlo.</p>
    HTML
    fees: <<~HTML,
      <h2>Publicar es gratis</h2>
      <p>Mientras estamos en fase de crecimiento, publicar y vender no tiene comisión. No hay cuota mensual ni coste por subir fotos.</p>
      <h2>Comisiones futuras</h2>
      <p>Si activamos una comisión por venta, se anunciará con antelación, se mostrará antes de publicar y solo se aplicará a ventas nuevas. La comisión se calcula sobre el subtotal del artículo, sin el envío.</p>
      <h2>Anuncios destacados</h2>
      <p>Destacar un anuncio es opcional. El precio se muestra antes de contratarlo y nunca se cobra de forma automática.</p>
      <h2>Impuestos</h2>
      <p>Los precios incluyen el IVA aplicable. Cada vendedor es responsable de sus obligaciones fiscales. %{local_note}</p>
    HTML
    accessibility: <<~HTML
      <h2>Nuestro compromiso</h2>
      <p>Queremos que PCMarket sea usable por el mayor número de personas posible. Trabajamos para cumplir las pautas WCAG 2.1 nivel AA en las páginas principales.</p>
      <h2>Medidas</h2>
      <ul><li>Navegación con teclado y foco visible.</li><li>Contraste revisado en temas claro y oscuro.</li><li>Textos alternativos y etiquetas accesibles.</li><li>Respeto a la preferencia de movimiento reducido.</li></ul>
      <h2>Limitaciones y contacto</h2>
      <p>Algunos documentos antiguos o contenidos de terceros pueden no cumplir todos los criterios. Si encuentras una barrera, escríbenos a %{email} e intentaremos resolverlo.</p>
    HTML
  },
  "en" => {
    terms: <<~HTML,
      <h2>What PCMarket is</h2>
      <p>PCMarket is an online marketplace that connects buyers and sellers of PC hardware and accessories. PCMarket is not the seller and is not a party to the sale contract: it acts as a technology and payment intermediary.</p>
      <h2>Obligations of the parties</h2>
      <p>Buyers agree to provide accurate details, pay the price and inspect the item on delivery. Sellers agree to describe the item accurately, prove they may sell it, dispatch it within the stated time and respect consumer rights.</p>
      <h2>Prices, payments and fees</h2>
      <p>Prices are shown in euros including applicable taxes. Payment is made on the platform through Stripe and is held until buyer protection is satisfied. Current fees are published on the fees page.</p>
      <h2>Prohibited items</h2>
      <p>Illegal, stolen, counterfeit, dangerous or rights-infringing items may not be listed. PCMarket may remove listings and suspend accounts.</p>
      <h2>Issues and disputes</h2>
      <p>Issues are handled from the order. %{consumer_law} protects consumers. Any dispute will be heard by %{courts}. %{odr_note}</p>
      <h2>Governing law</h2>
      <p>These terms are governed by the law of %{country}. %{local_note}</p>
    HTML
    privacy: <<~HTML,
      <h2>Data controller</h2>
      <p>The controller is %{company}, with its address at %{address} and email %{email}. Registration details appear in the legal notice.</p>
      <h2>Data we process</h2>
      <ul><li>Identity and contact: name, username, email, phone and address.</li><li>Activity: listings, messages, favourites, purchases and reviews.</li><li>Payments: amounts, status and Stripe references; we do not store card numbers.</li><li>Technical data: IP, device, language and cookies.</li></ul>
      <h2>Purposes and legal bases</h2>
      <p>We process data to perform the contract (account, sale and payments), comply with legal duties (invoicing and fraud prevention), pursue legitimate interests (security and service improvement) and, with your consent, send marketing.</p>
      <h2>Retention and recipients</h2>
      <p>We keep data for the relationship and statutory periods. Recipients are Stripe (payments), our hosting and email providers, and authorities where legally required. We do not sell personal data.</p>
      <h2>International transfers</h2>
      <p>Where a provider processes data outside the EEA, it relies on appropriate safeguards such as the European Commission standard contractual clauses.</p>
      <h2>Your rights</h2>
      <p>You may request access, rectification, erasure, objection, restriction and portability by writing to %{email}. You may also complain to %{authority}. %{local_note}</p>
      <h2>Cookies</h2>
      <p>Cookie use is explained in the <a href="%{cookies_path}">cookie policy</a>.</p>
    HTML
    cookies: <<~HTML,
      <h2>What cookies are</h2>
      <p>Cookies and local storage remember your session, preferences and, with permission, measure how the site is used. We do not set non-essential cookies before consent.</p>
      <h2>Categories</h2>
      <ul><li>Necessary: make the site work and cannot be disabled.</li><li>Preferences: remember language, country and theme.</li><li>Analytics: measure visits and pages used.</li><li>Marketing: measure campaigns and enable relevant advertising.</li></ul>
      <h2>Cookies we use</h2>
      <table><thead><tr><th>Name</th><th>Purpose</th><th>Duration</th><th>Category</th></tr></thead><tbody><tr><td>pcmarket_session</td><td>Session and security</td><td>Session</td><td>Necessary</td></tr><tr><td>locale</td><td>Chosen language</td><td>1 year</td><td>Preferences</td></tr><tr><td>country</td><td>Country for legal content</td><td>1 year</td><td>Preferences</td></tr><tr><td>cookie_consent</td><td>Stores your choice</td><td>6 months</td><td>Necessary</td></tr><tr><td>theme (localStorage)</td><td>Light or dark theme</td><td>Persistent</td><td>Preferences</td></tr><tr><td>__stripe_mid / __stripe_sid</td><td>Payment fraud prevention</td><td>1 year / session</td><td>Necessary</td></tr></tbody></table>
      <h2>Managing cookies</h2>
      <p>You can change your choice from “Cookie preferences” in the footer. You can also delete or block cookies in your browser, although some features will stop working.</p>
    HTML
    legal_notice: <<~HTML,
      <h2>Site owner</h2>
      <p>%{company}, tax ID %{tax_id}, address %{address}, email %{email}. Registration details: %{registry}.</p>
      <h2>Purpose</h2>
      <p>This site provides an intermediary service between buyers and sellers of hardware. Information is provided under %{company_law} and applicable e-commerce rules.</p>
      <h2>Intellectual property</h2>
      <p>The brand, design, copy and code belong to %{company} or its licensors. Reproduction is not permitted without authorisation, except for lawful uses.</p>
      <h2>Liability</h2>
      <p>PCMarket takes care over availability and security but is not responsible for user content or agreements between the parties, without prejudice to buyer protection.</p>
      <h2>Links</h2>
      <p>External links are provided for reference. We do not control their content and accept no responsibility for them. %{local_note}</p>
    HTML
    returns: <<~HTML,
      <h2>Buying from business sellers</h2>
      <p>If you buy from a business seller, %{consumer_law} gives you 14 calendar days to withdraw, subject to legal exceptions (personalised goods, opened hygiene seals or downloaded digital content). You do not need to give a reason.</p>
      <h2>Buying between private sellers</h2>
      <p>There is no statutory right of withdrawal between private sellers. Buyer protection still covers items that do not arrive, arrive damaged or do not match the description.</p>
      <h2>Legal guarantee</h2>
      <p>New goods bought from businesses carry a 3-year legal guarantee; second-hand goods at least 1 year, from delivery. The guarantee covers lack of conformity, not normal wear.</p>
      <h2>How to request a return</h2>
      <p>Open an issue from the order or write to %{email} before the deadline. Refunds go to the original payment method within 14 days of acceptance.</p>
      <h2>Model withdrawal form</h2>
      <p>To %{company}, %{address}, %{email}: “I hereby give notice that I withdraw from my contract for the sale of the following goods: [DESCRIPTION], ordered on [DATE] and received on [DATE]. Name: [NAME]. Address: [ADDRESS]. Date: [DATE].”</p>
    HTML
    seller_terms: <<~HTML,
      <h2>Who can sell</h2>
      <p>You must be of legal age, have a confirmed account and a store with accurate details. Business sellers must state their tax identity and meet consumer information duties.</p>
      <h2>Listing rules</h2>
      <p>Listings must describe the real product, its condition and included accessories. You may only sell goods you own or are authorised to sell, using your own photos.</p>
      <h2>Prices, taxes and shipping</h2>
      <p>Prices must include applicable taxes. Sellers are responsible for invoicing where required, choosing suitable transport and delivering within the stated time.</p>
      <h2>Payments and fees</h2>
      <p>Payments are received through the platform. Current fees are published on the fees page. Failure to pay a fee may restrict the account.</p>
      <h2>Suspension and liability</h2>
      <p>PCMarket may remove listings or suspend accounts that breach these terms. Sellers are responsible for their listings, sales, taxes and compliance with consumer rights.</p>
    HTML
    buyer_protection: <<~HTML,
      <h2>What is covered</h2>
      <p>Protection covers purchases paid inside PCMarket when the item does not arrive, arrives damaged, differs from the description, is counterfeit or the seller cancels after payment.</p>
      <h2>What is not covered</h2>
      <p>It does not cover off-platform payments, prohibited items, damage not reported in time, withdrawal between private sellers or normal wear.</p>
      <h2>How it works</h2>
      <p>We hold the payment, the seller ships with tracking and you inspect the item for %{days} days. If there is a problem, open an issue before the window closes.</p>
      <h2>Resolution and refunds</h2>
      <p>We review the issue and ask both parties for information. If accepted, we refund the original payment method and may recover the amount from the seller. Decisions include a statement of reasons.</p>
      <h2>Limits</h2>
      <p>Protection is a platform service and does not replace the legal rights granted by %{consumer_law}.</p>
    HTML
    dsa_transparency: <<~HTML,
      <h2>Point of contact</h2>
      <p>For communications about Regulation (EU) 2022/2065 (DSA), write to %{email}. We handle messages in English and Spanish.</p>
      <h2>Notice and action</h2>
      <p>Anyone can report allegedly illegal content through the report button. We acknowledge receipt, review the notice and communicate our decision.</p>
      <h2>Statement of reasons</h2>
      <p>When we remove content or suspend an account, we tell the affected person the reason, the scope of the measure and how to appeal.</p>
      <h2>Trader traceability</h2>
      <p>Business sellers must provide their identity, tax details and contact information. These details are shown on the listing where the law requires it.</p>
      <h2>Dispute settlement</h2>
      <p>Parties may use alternative dispute resolution bodies and the courts. %{odr_note}</p>
      <h2>Transparency</h2>
      <p>We publish aggregated information about notices received, measures taken and response times in our periodic reports. %{dsa_note}</p>
    HTML
    prohibited_items: <<~HTML,
      <h2>Prohibited items</h2>
      <p>Illegal, stolen, counterfeit or intellectual-property-infringing products may not be listed. Dangerous or regulated items without authorisation are also prohibited.</p>
      <h2>Indicative list</h2>
      <ul><li>Weapons, ammunition and prohibited replicas.</li><li>Drugs, controlled substances and precursors.</li><li>Child abuse material or illegal content.</li><li>Personal data, accounts and credentials.</li><li>Malware, illegal licences and fraud tools.</li><li>Damaged batteries or electrically unsafe components.</li><li>Products recalled for safety reasons.</li><li>Stolen goods or goods of unproven origin.</li></ul>
      <h2>Consequences</h2>
      <p>We remove listings, may suspend the account and, where appropriate, inform the authorities. If you are unsure about an item, ask us before listing it.</p>
    HTML
    fees: <<~HTML,
      <h2>Listing is free</h2>
      <p>While we are growing, listing and selling carries no commission. There is no monthly fee and no charge for uploading photos.</p>
      <h2>Future commission</h2>
      <p>If we enable a sales commission, it will be announced in advance, shown before publishing and applied only to new sales. It is calculated on the item subtotal, excluding shipping.</p>
      <h2>Featured listings</h2>
      <p>Featuring a listing is optional. The price is shown before purchase and is never charged automatically.</p>
      <h2>Taxes</h2>
      <p>Prices include applicable VAT. Each seller is responsible for their own tax obligations. %{local_note}</p>
    HTML
    accessibility: <<~HTML
      <h2>Our commitment</h2>
      <p>We want PCMarket to be usable by as many people as possible. We work towards WCAG 2.1 level AA on the main pages.</p>
      <h2>Measures</h2>
      <ul><li>Keyboard navigation and visible focus.</li><li>Contrast checked in light and dark themes.</li><li>Alternative text and accessible labels.</li><li>Respect for reduced-motion preferences.</li></ul>
      <h2>Limitations and contact</h2>
      <p>Some older documents or third-party content may not meet every criterion. If you find a barrier, write to %{email} and we will try to resolve it.</p>
    HTML
  },
  "fr" => {
    terms: <<~HTML,
      <h2>Qu'est-ce que PCMarket</h2>
      <p>PCMarket est une place de marché en ligne qui met en relation acheteurs et vendeurs de matériel et d'accessoires PC. PCMarket n'est pas le vendeur et n'est pas partie au contrat de vente : elle agit comme intermédiaire technique et de paiement.</p>
      <h2>Obligations des parties</h2>
      <p>L'acheteur s'engage à fournir des informations exactes, à payer le prix et à inspecter l'article à la livraison. Le vendeur s'engage à décrire l'article avec exactitude, à justifier qu'il peut le vendre, à l'expédier dans le délai indiqué et à respecter les droits des consommateurs.</p>
      <h2>Prix, paiements et frais</h2>
      <p>Les prix sont affichés en euros, taxes comprises. Le paiement s'effectue sur la plateforme via Stripe et reste retenu jusqu'à la validation de la protection de l'acheteur. Les frais en vigueur sont publiés sur la page des tarifs.</p>
      <h2>Articles interdits</h2>
      <p>Les articles illégaux, volés, contrefaits, dangereux ou portant atteinte aux droits de tiers sont interdits. PCMarket peut retirer des annonces et suspendre des comptes.</p>
      <h2>Litiges</h2>
      <p>Les litiges se gèrent depuis la commande. %{consumer_law} protège les consommateurs. Tout différend relève de %{courts}. %{odr_note}</p>
      <h2>Droit applicable</h2>
      <p>Ces conditions sont régies par le droit de %{country}. %{local_note}</p>
    HTML
    privacy: <<~HTML,
      <h2>Responsable du traitement</h2>
      <p>Le responsable est %{company}, domicilié à %{address}, courriel %{email}. Les données d'immatriculation figurent dans les mentions légales.</p>
      <h2>Données traitées</h2>
      <ul><li>Identité et contact : nom, pseudonyme, courriel, téléphone et adresse.</li><li>Activité : annonces, messages, favoris, achats et avis.</li><li>Paiements : montants, statut et références Stripe ; nous ne stockons pas les numéros de carte.</li><li>Données techniques : IP, appareil, langue et cookies.</li></ul>
      <h2>Finalités et bases légales</h2>
      <p>Nous traitons les données pour exécuter le contrat (compte, vente et paiements), respecter nos obligations légales (facturation et prévention de la fraude), poursuivre des intérêts légitimes (sécurité et amélioration du service) et, avec votre consentement, envoyer des communications commerciales.</p>
      <h2>Conservation et destinataires</h2>
      <p>Les données sont conservées pendant la relation et les délais légaux. Les destinataires sont Stripe (paiements), nos hébergeurs et prestataires de messagerie, et les autorités lorsque la loi l'exige. Nous ne vendons pas de données personnelles.</p>
      <h2>Transferts internationaux</h2>
      <p>Lorsqu'un prestataire traite des données hors de l'EEE, il applique des garanties appropriées, notamment les clauses contractuelles types de la Commission européenne.</p>
      <h2>Vos droits</h2>
      <p>Vous pouvez demander l'accès, la rectification, l'effacement, l'opposition, la limitation et la portabilité en écrivant à %{email}. Vous pouvez aussi saisir %{authority}. %{local_note}</p>
      <h2>Cookies</h2>
      <p>L'usage des cookies est décrit dans la <a href="%{cookies_path}">politique de cookies</a>.</p>
    HTML
    cookies: <<~HTML,
      <h2>Qu'est-ce qu'un cookie</h2>
      <p>Les cookies et le stockage local mémorisent votre session, vos préférences et, avec votre accord, mesurent l'usage du site. Aucun cookie non essentiel n'est déposé avant votre consentement.</p>
      <h2>Catégories</h2>
      <ul><li>Nécessaires : assurent le fonctionnement du site et ne peuvent être désactivés.</li><li>Préférences : mémorisent langue, pays et thème.</li><li>Analyse : mesurent les visites et les pages consultées.</li><li>Marketing : mesurent les campagnes et permettent une publicité pertinente.</li></ul>
      <h2>Cookies utilisés</h2>
      <table><thead><tr><th>Nom</th><th>Finalité</th><th>Durée</th><th>Catégorie</th></tr></thead><tbody><tr><td>pcmarket_session</td><td>Session et sécurité</td><td>Session</td><td>Nécessaire</td></tr><tr><td>locale</td><td>Langue choisie</td><td>1 an</td><td>Préférences</td></tr><tr><td>country</td><td>Pays pour le contenu légal</td><td>1 an</td><td>Préférences</td></tr><tr><td>cookie_consent</td><td>Conserve votre choix</td><td>6 mois</td><td>Nécessaire</td></tr><tr><td>theme (localStorage)</td><td>Thème clair ou sombre</td><td>Persistant</td><td>Préférences</td></tr><tr><td>__stripe_mid / __stripe_sid</td><td>Prévention de la fraude</td><td>1 an / session</td><td>Nécessaire</td></tr></tbody></table>
      <h2>Gestion</h2>
      <p>Vous pouvez modifier votre choix via « Préférences de cookies » en pied de page. Vous pouvez aussi supprimer ou bloquer les cookies dans votre navigateur, mais certaines fonctions cesseraient de marcher.</p>
    HTML
    legal_notice: <<~HTML,
      <h2>Éditeur du site</h2>
      <p>%{company}, identifiant fiscal %{tax_id}, domicilié à %{address}, courriel %{email}. Données d'immatriculation : %{registry}.</p>
      <h2>Objet</h2>
      <p>Ce site fournit un service d'intermédiation entre acheteurs et vendeurs de matériel. Les informations sont fournies conformément à %{company_law} et aux règles applicables au commerce électronique.</p>
      <h2>Propriété intellectuelle</h2>
      <p>La marque, le design, les textes et le code appartiennent à %{company} ou à ses concédants. Toute reproduction non autorisée est interdite, hors usages légaux.</p>
      <h2>Responsabilité</h2>
      <p>PCMarket veille à la disponibilité et à la sécurité du service, mais n'est pas responsable des contenus publiés par les utilisateurs ni des accords entre les parties, sans prejudice de la protection de l'acheteur.</p>
      <h2>Liens</h2>
      <p>Les liens externes sont fournis à titre indicatif. Nous ne contrôlons pas leur contenu et déclinons toute responsabilité à leur égard. %{local_note}</p>
    HTML
    returns: <<~HTML,
      <h2>Achats auprès de vendeurs professionnels</h2>
      <p>Si vous achetez à un vendeur professionnel, %{consumer_law} vous accorde 14 jours calendaires pour vous rétracter, sauf exceptions légales (biens personnalisés, scellés d'hygiène ouverts ou contenus numériques téléchargés). Aucun motif n'est requis.</p>
      <h2>Achats entre particuliers</h2>
      <p>Il n'existe pas de droit légal de rétractation entre particuliers. La protection de l'acheteur couvre néanmoins les articles non reçus, endommagés ou non conformes à la description.</p>
      <h2>Garantie légale</h2>
      <p>Les biens neufs achetés à un professionnel bénéficient d'une garantie légale de 3 ans ; les biens d'occasion, d'au moins 1 an à compter de la livraison. La garantie couvre le défaut de conformité, pas l'usure normale.</p>
      <h2>Demander un retour</h2>
      <p>Ouvrez un litige depuis la commande ou écrivez à %{email} avant l'échéance. Le remboursement est effectué sur le moyen de paiement d'origine dans les 14 jours suivant l'acceptation.</p>
      <h2>Formulaire type de rétractation</h2>
      <p>À %{company}, %{address}, %{email} : « Je vous notifie par la présente ma rétractation du contrat portant sur la vente du bien suivant : [DESCRIPTION], commandé le [DATE] et reçu le [DATE]. Nom : [NOM]. Adresse : [ADRESSE]. Date : [DATE]. »</p>
    HTML
    seller_terms: <<~HTML,
      <h2>Conditions pour vendre</h2>
      <p>Vous devez être majeur, disposer d'un compte confirmé et d'une boutique aux informations exactes. Les vendeurs professionnels doivent indiquer leur identité fiscale et respecter les obligations d'information des consommateurs.</p>
      <h2>Règles des annonces</h2>
      <p>Les annonces doivent décrire le produit réel, son état et les accessoires inclus. Vous ne pouvez vendre que des biens dont vous êtes propriétaire ou autorisé à vendre, avec vos propres photos.</p>
      <h2>Prix, taxes et livraison</h2>
      <p>Les prix doivent inclure les taxes applicables. Le vendeur est responsable de la facturation, du choix d'un transport adapté et du respect du délai de livraison.</p>
      <h2>Paiements et frais</h2>
      <p>Les paiements sont reçus via la plateforme. Les frais en vigueur sont publiés sur la page des tarifs. Le non-paiement d'un frais peut limiter le compte.</p>
      <h2>Suspension et responsabilité</h2>
      <p>PCMarket peut retirer des annonces ou suspendre les comptes qui enfreignent ces conditions. Le vendeur est responsable de ses annonces, ventes, taxes et du respect des droits des consommateurs.</p>
    HTML
    buyer_protection: <<~HTML,
      <h2>Ce qui est couvert</h2>
      <p>La protection couvre les achats payés sur PCMarket lorsque l'article n'arrive pas, arrive endommagé, diffère de la description, est contrefait ou lorsque le vendeur annule après le paiement.</p>
      <h2>Ce qui n'est pas couvert</h2>
      <p>Elle ne couvre pas les paiements hors plateforme, les articles interdits, les dommages non signalés à temps, la rétractation entre particuliers ni l'usure normale.</p>
      <h2>Fonctionnement</h2>
      <p>Nous retenons le paiement, le vendeur expédie avec suivi et vous inspectez l'article pendant %{days} jours. En cas de problème, ouvrez un litige avant la fin du délai.</p>
      <h2>Résolution et remboursements</h2>
      <p>Nous examinons le litige et demandons des informations aux deux parties. S'il est accepté, nous remboursons le moyen de paiement d'origine et pouvons récupérer le montant auprès du vendeur. Les décisions sont motivées.</p>
      <h2>Limites</h2>
      <p>La protection est un service de la plateforme et ne remplace pas les droits légaux accordés par %{consumer_law}.</p>
    HTML
    dsa_transparency: <<~HTML,
      <h2>Point de contact</h2>
      <p>Pour toute communication relative au règlement (UE) 2022/2065 (DSA), écrivez à %{email}. Nous répondons en français et en anglais.</p>
      <h2>Notification et action</h2>
      <p>Toute personne peut signaler un contenu prétendument illégal via le bouton de signalement. Nous accusons réception, examinons le signalement et communiquons notre décision.</p>
      <h2>Exposé des motifs</h2>
      <p>Lorsque nous retirons un contenu ou suspendons un compte, nous indiquons à la personne concernée le motif, la portée de la mesure et les voies de recours.</p>
      <h2>Traçabilité des professionnels</h2>
      <p>Les vendeurs professionnels doivent fournir leur identité, leurs données fiscales et leurs coordonnées. Ces informations figurent sur l'annonce lorsque la loi l'exige.</p>
      <h2>Règlement des litiges</h2>
      <p>Les parties peuvent recourir aux organismes de règlement extrajudiciaire et aux tribunaux. %{odr_note}</p>
      <h2>Transparence</h2>
      <p>Nous publions des informations agrégées sur les signalements reçus, les mesures prises et les délais de réponse. %{dsa_note}</p>
    HTML
    prohibited_items: <<~HTML,
      <h2>Articles interdits</h2>
      <p>Les produits illégaux, volés, contrefaits ou portant atteinte à la propriété intellectuelle sont interdits. Les articles dangereux ou réglementés sans autorisation le sont aussi.</p>
      <h2>Liste indicative</h2>
      <ul><li>Armes, munitions et répliques interdites.</li><li>Drogues, substances contrôlées et précurseurs.</li><li>Contenus d'abus sur mineurs ou illégaux.</li><li>Données personnelles, comptes et identifiants.</li><li>Logiciels malveillants, licences illégales et outils de fraude.</li><li>Batteries endommagées ou composants électriquement dangereux.</li><li>Produits rappelés pour des raisons de sécurité.</li><li>Biens volés ou d'origine non prouvée.</li></ul>
      <h2>Conséquences</h2>
      <p>Nous retirons les annonces, pouvons suspendre le compte et, le cas échéant, informons les autorités. En cas de doute, demandez-nous avant de publier.</p>
    HTML
    fees: <<~HTML,
      <h2>Publier est gratuit</h2>
      <p>Pendant notre croissance, publier et vendre ne donne lieu à aucune commission. Il n'y a ni abonnement mensuel ni frais pour ajouter des photos.</p>
      <h2>Commission future</h2>
      <p>Si nous activons une commission, elle sera annoncée à l'avance, affichée avant publication et appliquée uniquement aux nouvelles ventes. Elle est calculée sur le sous-total de l'article, hors livraison.</p>
      <h2>Annonces mises en avant</h2>
      <p>La mise en avant est facultative. Le prix est affiché avant l'achat et n'est jamais prélevé automatiquement.</p>
      <h2>Taxes</h2>
      <p>Les prix incluent la TVA applicable. Chaque vendeur est responsable de ses obligations fiscales. %{local_note}</p>
    HTML
    accessibility: <<~HTML
      <h2>Notre engagement</h2>
      <p>Nous voulons que PCMarket soit utilisable par le plus grand nombre. Nous travaillons à respecter les WCAG 2.1 niveau AA sur les pages principales.</p>
      <h2>Mesures</h2>
      <ul><li>Navigation au clavier et focus visible.</li><li>Contrastes vérifiés en thème clair et sombre.</li><li>Textes alternatifs et libellés accessibles.</li><li>Respect de la préférence de mouvement réduit.</li></ul>
      <h2>Limites et contact</h2>
      <p>Certains documents anciens ou contenus tiers peuvent ne pas respecter tous les critères. Si vous rencontrez un obstacle, écrivez à %{email} et nous tenterons de le résoudre.</p>
    HTML
  },
  "de" => {
    terms: <<~HTML,
      <h2>Was PCMarket ist</h2>
      <p>PCMarket ist ein Online-Marktplatz, der Käufer und Verkäufer von PC-Hardware und Zubehör zusammenbringt. PCMarket ist nicht der Verkäufer und nicht Partei des Kaufvertrags, sondern handelt als technischer und Zahlungsvermittler.</p>
      <h2>Pflichten der Parteien</h2>
      <p>Käufer verpflichten sich, korrekte Angaben zu machen, den Preis zu zahlen und den Artikel bei Lieferung zu prüfen. Verkäufer verpflichten sich, den Artikel wahrheitsgemäß zu beschreiben, ihre Verkaufsberechtigung nachzuweisen, fristgerecht zu versenden und Verbraucherrechte zu achten.</p>
      <h2>Preise, Zahlungen und Gebühren</h2>
      <p>Preise werden in Euro inklusive anwendbarer Steuern angezeigt. Die Zahlung erfolgt über Stripe auf der Plattform und wird bis zur Erfüllung des Käuferschutzes zurückgehalten. Aktuelle Gebühren stehen auf der Gebührenseite.</p>
      <h2>Verbotene Artikel</h2>
      <p>Illegale, gestohlene, gefälschte, gefährliche oder rechtsverletzende Artikel dürfen nicht eingestellt werden. PCMarket kann Anzeigen entfernen und Konten sperren.</p>
      <h2>Probleme und Streitigkeiten</h2>
      <p>Probleme werden über die Bestellung bearbeitet. %{consumer_law} schützt Verbraucher. Für Streitigkeiten sind %{courts} zuständig. %{odr_note}</p>
      <h2>Anwendbares Recht</h2>
      <p>Diese Bedingungen unterliegen dem Recht von %{country}. %{local_note}</p>
    HTML
    privacy: <<~HTML,
      <h2>Verantwortlicher</h2>
      <p>Verantwortlich ist %{company}, Anschrift %{address}, E-Mail %{email}. Registerdaten stehen im Impressum.</p>
      <h2>Verarbeitete Daten</h2>
      <ul><li>Identität und Kontakt: Name, Benutzername, E-Mail, Telefon und Adresse.</li><li>Aktivität: Anzeigen, Nachrichten, Favoriten, Käufe und Bewertungen.</li><li>Zahlungen: Beträge, Status und Stripe-Referenzen; Kartennummern speichern wir nicht.</li><li>Technische Daten: IP, Gerät, Sprache und Cookies.</li></ul>
      <h2>Zwecke und Rechtsgrundlagen</h2>
      <p>Wir verarbeiten Daten zur Vertragserfüllung (Konto, Kauf und Zahlungen), zur Erfüllung gesetzlicher Pflichten (Rechnungsstellung und Betrugsprävention), aufgrund berechtigter Interessen (Sicherheit und Serviceverbesserung) und mit deiner Einwilligung für Werbung.</p>
      <h2>Aufbewahrung und Empfänger</h2>
      <p>Wir speichern Daten für die Dauer der Beziehung und gesetzliche Fristen. Empfänger sind Stripe (Zahlungen), Hosting- und E-Mail-Anbieter sowie Behörden, soweit gesetzlich erforderlich. Wir verkaufen keine personenbezogenen Daten.</p>
      <h2>Internationale Übermittlungen</h2>
      <p>Verarbeitet ein Anbieter Daten außerhalb des EWR, stützt er sich auf geeignete Garantien wie die Standardvertragsklauseln der Europäischen Kommission.</p>
      <h2>Deine Rechte</h2>
      <p>Du kannst Auskunft, Berichtigung, Löschung, Widerspruch, Einschränkung und Übertragbarkeit unter %{email} verlangen. Du kannst dich auch bei %{authority} beschweren. %{local_note}</p>
      <h2>Cookies</h2>
      <p>Die Cookie-Nutzung ist in der <a href="%{cookies_path}">Cookie-Richtlinie</a> erklärt.</p>
    HTML
    cookies: <<~HTML,
      <h2>Was Cookies sind</h2>
      <p>Cookies und lokaler Speicher merken sich deine Sitzung, Einstellungen und, mit Erlaubnis, die Nutzung der Website. Nicht notwendige Cookies setzen wir erst nach deiner Einwilligung.</p>
      <h2>Kategorien</h2>
      <ul><li>Notwendig: ermöglichen die Website und können nicht deaktiviert werden.</li><li>Präferenzen: merken Sprache, Land und Theme.</li><li>Analyse: messen Besuche und genutzte Seiten.</li><li>Marketing: messen Kampagnen und ermöglichen relevante Werbung.</li></ul>
      <h2>Verwendete Cookies</h2>
      <table><thead><tr><th>Name</th><th>Zweck</th><th>Dauer</th><th>Kategorie</th></tr></thead><tbody><tr><td>pcmarket_session</td><td>Sitzung und Sicherheit</td><td>Sitzung</td><td>Notwendig</td></tr><tr><td>locale</td><td>Gewählte Sprache</td><td>1 Jahr</td><td>Präferenzen</td></tr><tr><td>country</td><td>Land für rechtliche Inhalte</td><td>1 Jahr</td><td>Präferenzen</td></tr><tr><td>cookie_consent</td><td>Speichert deine Wahl</td><td>6 Monate</td><td>Notwendig</td></tr><tr><td>theme (localStorage)</td><td>Helles oder dunkles Theme</td><td>Dauerhaft</td><td>Präferenzen</td></tr><tr><td>__stripe_mid / __stripe_sid</td><td>Betrugsprävention bei Zahlungen</td><td>1 Jahr / Sitzung</td><td>Notwendig</td></tr></tbody></table>
      <h2>Verwaltung</h2>
      <p>Du kannst deine Wahl über „Cookie-Einstellungen“ in der Fußzeile ändern. Du kannst Cookies auch im Browser löschen oder blockieren; einige Funktionen funktionieren dann nicht mehr.</p>
    HTML
    legal_notice: <<~HTML,
      <h2>Anbieter</h2>
      <p>%{company}, Steuer-ID %{tax_id}, Anschrift %{address}, E-Mail %{email}. Registerdaten: %{registry}.</p>
      <h2>Zweck</h2>
      <p>Diese Website bietet eine Vermittlungsleistung zwischen Käufern und Verkäufern von Hardware. Die Angaben erfolgen nach %{company_law} und den anwendbaren E-Commerce-Regeln.</p>
      <h2>Urheberrecht</h2>
      <p>Marke, Design, Texte und Code gehören %{company} oder ihren Lizenzgebern. Eine Vervielfältigung ohne Erlaubnis ist außerhalb gesetzlicher Nutzungen nicht gestattet.</p>
      <h2>Haftung</h2>
      <p>PCMarket achtet auf Verfügbarkeit und Sicherheit, haftet aber nicht für Nutzerinhalte oder Vereinbarungen zwischen den Parteien, unbeschadet des Käuferschutzes.</p>
      <h2>Links</h2>
      <p>Externe Links dienen nur zur Information. Wir kontrollieren ihre Inhalte nicht und übernehmen keine Haftung. %{local_note}</p>
    HTML
    returns: <<~HTML,
      <h2>Käufe bei gewerblichen Verkäufern</h2>
      <p>Bei einem gewerblichen Verkäufer gibt dir %{consumer_law} 14 Kalendertage Widerrufsrecht, vorbehaltlich gesetzlicher Ausnahmen (personalisierte Waren, geöffnete Hygienesiegel oder heruntergeladene digitale Inhalte). Ein Grund ist nicht erforderlich.</p>
      <h2>Käufe zwischen Privatpersonen</h2>
      <p>Zwischen Privatpersonen gibt es kein gesetzliches Widerrufsrecht. Der Käuferschutz deckt dennoch Artikel ab, die nicht ankommen, beschädigt ankommen oder nicht der Beschreibung entsprechen.</p>
      <h2>Gesetzliche Gewährleistung</h2>
      <p>Neue Waren von gewerblichen Verkäufern haben 3 Jahre Gewährleistung, gebrauchte mindestens 1 Jahr ab Lieferung. Die Gewährleistung deckt Sachmängel, nicht normalen Verschleiß.</p>
      <h2>Rückgabe beantragen</h2>
      <p>Eröffne ein Problem über die Bestellung oder schreibe vor Ablauf der Frist an %{email}. Die Erstattung erfolgt innerhalb von 14 Tagen nach Annahme auf das ursprüngliche Zahlungsmittel.</p>
      <h2>Muster-Widerrufsformular</h2>
      <p>An %{company}, %{address}, %{email}: „Hiermit widerrufe ich den von mir abgeschlossenen Vertrag über den Kauf der folgenden Ware: [BESCHREIBUNG], bestellt am [DATUM] und erhalten am [DATUM]. Name: [NAME]. Anschrift: [ANSCHRIFT]. Datum: [DATUM].“</p>
    HTML
    seller_terms: <<~HTML,
      <h2>Wer verkaufen darf</h2>
      <p>Du musst volljährig sein, ein bestätigtes Konto und einen Shop mit korrekten Angaben haben. Gewerbliche Verkäufer müssen ihre steuerliche Identität angeben und Verbraucherinformationen erfüllen.</p>
      <h2>Regeln für Anzeigen</h2>
      <p>Anzeigen müssen das reale Produkt, seinen Zustand und enthaltenes Zubehör beschreiben. Du darfst nur Waren verkaufen, die dir gehören oder zu deren Verkauf du berechtigt bist, mit eigenen Fotos.</p>
      <h2>Preise, Steuern und Versand</h2>
      <p>Preise müssen anwendbare Steuern enthalten. Verkäufer sind für Rechnungen, geeigneten Versand und die Einhaltung der Lieferfrist verantwortlich.</p>
      <h2>Zahlungen und Gebühren</h2>
      <p>Zahlungen werden über die Plattform abgewickelt. Aktuelle Gebühren stehen auf der Gebührenseite. Die Nichtzahlung einer Gebühr kann das Konto einschränken.</p>
      <h2>Sperrung und Haftung</h2>
      <p>PCMarket kann Anzeigen entfernen oder Konten sperren, die gegen diese Bedingungen verstoßen. Verkäufer haften für ihre Anzeigen, Verkäufe, Steuern und die Einhaltung von Verbraucherrechten.</p>
    HTML
    buyer_protection: <<~HTML,
      <h2>Was abgedeckt ist</h2>
      <p>Der Schutz gilt für Zahlungen innerhalb von PCMarket, wenn der Artikel nicht ankommt, beschädigt ankommt, von der Beschreibung abweicht, gefälscht ist oder der Verkäufer nach der Zahlung storniert.</p>
      <h2>Was nicht abgedeckt ist</h2>
      <p>Nicht abgedeckt sind Zahlungen außerhalb der Plattform, verbotene Artikel, nicht fristgerecht gemeldete Schäden, Widerruf zwischen Privatpersonen und normaler Verschleiß.</p>
      <h2>So funktioniert es</h2>
      <p>Wir halten die Zahlung zurück, der Verkäufer versendet mit Sendungsverfolgung und du prüfst den Artikel %{days} Tage lang. Bei Problemen eröffne vor Ablauf der Frist ein Problem.</p>
      <h2>Lösung und Erstattungen</h2>
      <p>Wir prüfen den Fall und bitten beide Seiten um Informationen. Bei Annahme erstatten wir auf das ursprüngliche Zahlungsmittel und können den Betrag vom Verkäufer zurückholen. Entscheidungen werden begründet.</p>
      <h2>Grenzen</h2>
      <p>Der Schutz ist eine Plattformleistung und ersetzt nicht die gesetzlichen Rechte nach %{consumer_law}.</p>
    HTML
    dsa_transparency: <<~HTML,
      <h2>Kontaktstelle</h2>
      <p>Für Mitteilungen zur Verordnung (EU) 2022/2065 (DSA) schreibe an %{email}. Wir bearbeiten Deutsch und Englisch.</p>
      <h2>Meldung und Maßnahme</h2>
      <p>Jede Person kann mutmaßlich rechtswidrige Inhalte über die Meldefunktion melden. Wir bestätigen den Eingang, prüfen die Meldung und teilen die Entscheidung mit.</p>
      <h2>Begründung</h2>
      <p>Wenn wir Inhalte entfernen oder ein Konto sperren, nennen wir der betroffenen Person den Grund, den Umfang der Maßnahme und den Rechtsbehelf.</p>
      <h2>Händler-Rückverfolgbarkeit</h2>
      <p>Gewerbliche Verkäufer müssen Identität, Steuerdaten und Kontakt angeben. Diese Angaben erscheinen in der Anzeige, soweit gesetzlich erforderlich.</p>
      <h2>Streitbeilegung</h2>
      <p>Die Parteien können Verbraucherschlichtungsstellen und Gerichte nutzen. %{odr_note}</p>
      <h2>Transparenz</h2>
      <p>Wir veröffentlichen aggregierte Informationen zu Meldungen, Maßnahmen und Antwortzeiten in regelmäßigen Berichten. %{dsa_note}</p>
    HTML
    prohibited_items: <<~HTML,
      <h2>Verbotene Artikel</h2>
      <p>Illegale, gestohlene, gefälschte oder urheberrechtsverletzende Produkte dürfen nicht eingestellt werden. Gefährliche oder regulierte Artikel ohne Genehmigung sind ebenfalls verboten.</p>
      <h2>Beispielliste</h2>
      <ul><li>Waffen, Munition und verbotene Nachbildungen.</li><li>Drogen, kontrollierte Substanzen und Vorläufer.</li><li>Missbrauchsmaterial oder illegale Inhalte.</li><li>Personenbezogene Daten, Konten und Zugangsdaten.</li><li>Schadsoftware, illegale Lizenzen und Betrugswerkzeuge.</li><li>Beschädigte Akkus oder elektrisch unsichere Komponenten.</li><li>Aus Sicherheitsgründen zurückgerufene Produkte.</li><li>Gestohlene Waren oder Waren ungeklärter Herkunft.</li></ul>
      <h2>Folgen</h2>
      <p>Wir entfernen Anzeigen, können das Konto sperren und gegebenenfalls Behörden informieren. Bei Unsicherheit frage vor dem Einstellen nach.</p>
    HTML
    fees: <<~HTML,
      <h2>Einstellen ist kostenlos</h2>
      <p>Während unserer Wachstumsphase ist das Einstellen und Verkaufen provisionsfrei. Es gibt keine Monatsgebühr und keine Kosten für Fotos.</p>
      <h2>Künftige Provision</h2>
      <p>Führen wir eine Verkaufsprovision ein, kündigen wir sie vorher an, zeigen sie vor der Veröffentlichung und wenden sie nur auf neue Verkäufe an. Sie wird auf den Artikel-Zwischensumme ohne Versand berechnet.</p>
      <h2>Hervorgehobene Anzeigen</h2>
      <p>Hervorhebungen sind optional. Der Preis wird vor dem Kauf angezeigt und nie automatisch abgebucht.</p>
      <h2>Steuern</h2>
      <p>Preise enthalten die anwendbare Umsatzsteuer. Jeder Verkäufer ist für seine steuerlichen Pflichten verantwortlich. %{local_note}</p>
    HTML
    accessibility: <<~HTML
      <h2>Unser Engagement</h2>
      <p>PCMarket soll für möglichst viele Menschen nutzbar sein. Wir arbeiten an WCAG 2.1 Level AA auf den Hauptseiten.</p>
      <h2>Maßnahmen</h2>
      <ul><li>Tastaturnavigation und sichtbarer Fokus.</li><li>Geprüfte Kontraste in hellem und dunklem Theme.</li><li>Alternativtexte und zugängliche Beschriftungen.</li><li>Respekt für reduzierte Bewegung.</li></ul>
      <h2>Grenzen und Kontakt</h2>
      <p>Ältere Dokumente oder Inhalte Dritter erfüllen möglicherweise nicht alle Kriterien. Wenn du auf eine Barriere stößt, schreibe an %{email} und wir versuchen zu helfen.</p>
    HTML
  },
  "it" => {
    terms: <<~HTML,
      <h2>Che cos'è PCMarket</h2>
      <p>PCMarket è un mercato online che mette in contatto acquirenti e venditori di hardware e accessori per PC. PCMarket non è il venditore e non è parte del contratto di vendita: agisce come intermediario tecnologico e di pagamento.</p>
      <h2>Obblighi delle parti</h2>
      <p>L'acquirente si impegna a fornire dati veritieri, pagare il prezzo e controllare l'articolo alla consegna. Il venditore si impegna a descrivere l'articolo con precisione, dimostrare di poterlo vendere, spedirlo nei tempi indicati e rispettare i diritti dei consumatori.</p>
      <h2>Prezzi, pagamenti e commissioni</h2>
      <p>I prezzi sono in euro, imposte incluse. Il pagamento avviene sulla piattaforma tramite Stripe e resta trattenuto fino al completamento della protezione dell'acquirente. Le commissioni vigenti sono pubblicate nella pagina delle tariffe.</p>
      <h2>Articoli vietati</h2>
      <p>Non si possono pubblicare articoli illegali, rubati, contraffatti, pericolosi o che violino diritti di terzi. PCMarket può rimuovere annunci e sospendere account.</p>
      <h2>Problemi e controversie</h2>
      <p>I problemi si gestiscono dall'ordine. %{consumer_law} protegge i consumatori. Per qualsiasi controversia sono competenti %{courts}. %{odr_note}</p>
      <h2>Legge applicabile</h2>
      <p>Questi termini sono regolati dalla legge di %{country}. %{local_note}</p>
    HTML
    privacy: <<~HTML,
      <h2>Titolare del trattamento</h2>
      <p>Il titolare è %{company}, con sede in %{address} e email %{email}. I dati di registrazione sono nelle note legali.</p>
      <h2>Dati trattati</h2>
      <ul><li>Identità e contatti: nome, username, email, telefono e indirizzo.</li><li>Attività: annunci, messaggi, preferiti, acquisti e recensioni.</li><li>Pagamenti: importi, stato e riferimenti Stripe; non memorizziamo i numeri di carta.</li><li>Dati tecnici: IP, dispositivo, lingua e cookie.</li></ul>
      <h2>Finalità e basi giuridiche</h2>
      <p>Trattiamo i dati per eseguire il contratto (account, vendita e pagamenti), adempiere a obblighi legali (fatturazione e prevenzione frodi), perseguire interessi legittimi (sicurezza e miglioramento del servizio) e, con il consenso, inviare comunicazioni commerciali.</p>
      <h2>Conservazione e destinatari</h2>
      <p>Conserviamo i dati per la durata del rapporto e i termini di legge. I destinatari sono Stripe (pagamenti), i fornitori di hosting ed email e le autorità quando richiesto. Non vendiamo dati personali.</p>
      <h2>Trasferimenti internazionali</h2>
      <p>Se un fornitore tratta dati fuori dal SEE, applica garanzie adeguate come le clausole contrattuali standard della Commissione europea.</p>
      <h2>Diritti</h2>
      <p>Puoi richiedere accesso, rettifica, cancellazione, opposizione, limitazione e portabilità scrivendo a %{email}. Puoi anche reclutare %{authority}. %{local_note}</p>
      <h2>Cookie</h2>
      <p>L'uso dei cookie è spiegato nell'<a href="%{cookies_path}">informativa sui cookie</a>.</p>
    HTML
    cookies: <<~HTML,
      <h2>Che cosa sono i cookie</h2>
      <p>Cookie e archiviazione locale ricordano la sessione, le preferenze e, con il consenso, misurano l'uso del sito. Non impostiamo cookie non essenziali prima del consenso.</p>
      <h2>Categorie</h2>
      <ul><li>Necessari: fanno funzionare il sito e non sono disattivabili.</li><li>Preferenze: ricordano lingua, paese e tema.</li><li>Analisi: misurano visite e pagine usate.</li><li>Marketing: misurano campagne e consentono pubblicità pertinente.</li></ul>
      <h2>Cookie utilizzati</h2>
      <table><thead><tr><th>Nome</th><th>Finalità</th><th>Durata</th><th>Categoria</th></tr></thead><tbody><tr><td>pcmarket_session</td><td>Sessione e sicurezza</td><td>Sessione</td><td>Necessario</td></tr><tr><td>locale</td><td>Lingua scelta</td><td>1 anno</td><td>Preferenze</td></tr><tr><td>country</td><td>Paese per i contenuti legali</td><td>1 anno</td><td>Preferenze</td></tr><tr><td>cookie_consent</td><td>Salva la tua scelta</td><td>6 mesi</td><td>Necessario</td></tr><tr><td>theme (localStorage)</td><td>Tema chiaro o scuro</td><td>Persistente</td><td>Preferenze</td></tr><tr><td>__stripe_mid / __stripe_sid</td><td>Prevenzione frodi nei pagamenti</td><td>1 anno / sessione</td><td>Necessario</td></tr></tbody></table>
      <h2>Gestione</h2>
      <p>Puoi cambiare scelta da “Preferenze cookie” nel footer. Puoi anche eliminare o bloccare i cookie nel browser, ma alcune funzioni smetteranno di funzionare.</p>
    HTML
    legal_notice: <<~HTML,
      <h2>Titolare del sito</h2>
      <p>%{company}, P.IVA %{tax_id}, sede in %{address}, email %{email}. Dati di registrazione: %{registry}.</p>
      <h2>Oggetto</h2>
      <p>Il sito offre un servizio di intermediazione tra acquirenti e venditori di hardware. Le informazioni sono fornite ai sensi di %{company_law} e della normativa applicabile sul commercio elettronico.</p>
      <h2>Proprietà intellettuale</h2>
      <p>Marchio, design, testi e codice appartengono a %{company} o ai suoi licenzianti. La riproduzione non autorizzata è vietata, salvo usi legali.</p>
      <h2>Responsabilità</h2>
      <p>PCMarket cura disponibilità e sicurezza ma non risponde dei contenuti degli utenti né degli accordi tra le parti, ferma restando la protezione dell'acquirente.</p>
      <h2>Link</h2>
      <p>I link esterni sono forniti come riferimento. Non ne controlliamo il contenuto e non ne rispondiamo. %{local_note}</p>
    HTML
    returns: <<~HTML,
      <h2>Acquisti da venditori professionisti</h2>
      <p>Se acquisti da un venditore professionista, %{consumer_law} ti riconosce 14 giorni di calendario per recedere, salvo eccezioni di legge (beni personalizzati, sigilli igienici aperti o contenuti digitali scaricati). Non serve motivare la decisione.</p>
      <h2>Acquisti tra privati</h2>
      <p>Tra privati non esiste un diritto legale di recesso. La protezione dell'acquirente copre comunque articoli non ricevuti, danneggiati o non conformi alla descrizione.</p>
      <h2>Garanzia legale</h2>
      <p>I beni nuovi acquistati da professionisti hanno una garanzia legale di 3 anni; quelli usati di almeno 1 anno dalla consegna. La garanzia copre il difetto di conformità, non l'usura normale.</p>
      <h2>Come chiedere un reso</h2>
      <p>Apri una segnalazione dall'ordine o scrivi a %{email} prima della scadenza. Il rimborso avviene sullo stesso metodo di pagamento entro 14 giorni dall'accettazione.</p>
      <h2>Modulo di recesso</h2>
      <p>A %{company}, %{address}, %{email}: «Con la presente notifico il recesso dal contratto di vendita del seguente bene: [DESCRIZIONE], ordinato il [DATA] e ricevuto il [DATA]. Nome: [NOME]. Indirizzo: [INDIRIZZO]. Data: [DATA].»</p>
    HTML
    seller_terms: <<~HTML,
      <h2>Chi può vendere</h2>
      <p>Devi essere maggiorenne, avere un account confermato e un negozio con dati veritieri. I venditori professionisti devono indicare l'identità fiscale e rispettare gli obblighi informativi verso i consumatori.</p>
      <h2>Regole degli annunci</h2>
      <p>Gli annunci devono descrivere il prodotto reale, le condizioni e gli accessori inclusi. Puoi vendere solo beni di tua proprietà o che sei autorizzato a vendere, con foto proprie.</p>
      <h2>Prezzi, imposte e spedizioni</h2>
      <p>I prezzi devono includere le imposte applicabili. Il venditore è responsabile della fatturazione, della scelta di un trasporto adeguato e del rispetto dei tempi di consegna.</p>
      <h2>Pagamenti e commissioni</h2>
      <p>I pagamenti si ricevono tramite la piattaforma. Le commissioni vigenti sono pubblicate nella pagina delle tariffe. Il mancato pagamento può limitare l'account.</p>
      <h2>Sospensione e responsabilità</h2>
      <p>PCMarket può rimuovere annunci o sospendere account che violano questi termini. Il venditore risponde dei propri annunci, vendite, imposte e del rispetto dei diritti dei consumatori.</p>
    HTML
    buyer_protection: <<~HTML,
      <h2>Cosa copre</h2>
      <p>La protezione copre gli acquisti pagati su PCMarket quando l'articolo non arriva, arriva danneggiato, è diverso dalla descrizione, è contraffatto o il venditore annulla dopo il pagamento.</p>
      <h2>Cosa non copre</h2>
      <p>Non copre pagamenti fuori dalla piattaforma, articoli vietati, danni non segnalati in tempo, recesso tra privati o usura normale.</p>
      <h2>Come funziona</h2>
      <p>Tratteniamo il pagamento, il venditore spedisce con tracciamento e tu controlli l'articolo per %{days} giorni. In caso di problema, apri una segnalazione prima della scadenza.</p>
      <h2>Risoluzione e rimborsi</h2>
      <p>Esaminiamo la segnalazione e chiediamo informazioni a entrambe le parti. Se accettata, rimborsiamo il metodo di pagamento originale e possiamo recuperare l'importo dal venditore. Le decisioni sono motivate.</p>
      <h2>Limiti</h2>
      <p>La protezione è un servizio della piattaforma e non sostituisce i diritti legali riconosciuti da %{consumer_law}.</p>
    HTML
    dsa_transparency: <<~HTML,
      <h2>Punto di contatto</h2>
      <p>Per comunicazioni sul Regolamento (UE) 2022/2065 (DSA) scrivi a %{email}. Rispondiamo in italiano e inglese.</p>
      <h2>Notifica e azione</h2>
      <p>Chiunque può segnalare contenuti presuntamente illegali tramite il pulsante di segnalazione. Confermiamo la ricezione, esaminiamo la segnalazione e comunichiamo la decisione.</p>
      <h2>Motivazione</h2>
      <p>Quando rimuoviamo contenuti o sospendiamo un account, indichiamo alla persona interessata il motivo, la portata della misura e come ricorrere.</p>
      <h2>Tracciabilità dei professionisti</h2>
      <p>I venditori professionisti devono fornire identità, dati fiscali e contatti. Questi dati compaiono nell'annuncio quando la legge lo richiede.</p>
      <h2>Risoluzione delle controversie</h2>
      <p>Le parti possono rivolgersi agli organismi di risoluzione alternativa e ai tribunali. %{odr_note}</p>
      <h2>Trasparenza</h2>
      <p>Pubblichiamo informazioni aggregate su segnalazioni, misure e tempi di risposta nei nostri report periodici. %{dsa_note}</p>
    HTML
    prohibited_items: <<~HTML,
      <h2>Articoli vietati</h2>
      <p>Non si possono pubblicare prodotti illegali, rubati, contraffatti o che violano la proprietà intellettuale. Sono vietati anche articoli pericolosi o regolamentati senza autorizzazione.</p>
      <h2>Elenco indicativo</h2>
      <ul><li>Armi, munizioni e repliche vietate.</li><li>Droga, sostanze controllate e precursori.</li><li>Materiale di abuso su minori o contenuti illegali.</li><li>Dati personali, account e credenziali.</li><li>Malware, licenze illegali e strumenti di frode.</li><li>Batterie danneggiate o componenti elettricamente pericolosi.</li><li>Prodotti richiamati per sicurezza.</li><li>Beni rubati o di provenienza non dimostrata.</li></ul>
      <h2>Conseguenze</h2>
      <p>Rimuoviamo gli annunci, possiamo sospendere l'account e, se necessario, informare le autorità. In caso di dubbio, chiedici prima di pubblicare.</p>
    HTML
    fees: <<~HTML,
      <h2>Pubblicare è gratis</h2>
      <p>Durante la crescita, pubblicare e vendere non prevede commissioni. Non ci sono canoni mensili né costi per caricare foto.</p>
      <h2>Commissione futura</h2>
      <p>Se attiveremo una commissione, sarà annunciata in anticipo, mostrata prima della pubblicazione e applicata solo alle nuove vendite. È calcolata sul subtotale dell'articolo, esclusa la spedizione.</p>
      <h2>Annunci in evidenza</h2>
      <p>La messa in evidenza è facoltativa. Il prezzo è mostrato prima dell'acquisto e non viene mai addebitato automaticamente.</p>
      <h2>Imposte</h2>
      <p>I prezzi includono l'IVA applicabile. Ogni venditore è responsabile dei propri obblighi fiscali. %{local_note}</p>
    HTML
    accessibility: <<~HTML
      <h2>Il nostro impegno</h2>
      <p>Vogliamo che PCMarket sia utilizzabile dal maggior numero di persone. Lavoriamo per rispettare le WCAG 2.1 livello AA nelle pagine principali.</p>
      <h2>Misure</h2>
      <ul><li>Navigazione da tastiera e focus visibile.</li><li>Contrasti verificati in tema chiaro e scuro.</li><li>Testi alternativi ed etichette accessibili.</li><li>Rispetto della preferenza di movimento ridotto.</li></ul>
      <h2>Limiti e contatti</h2>
      <p>Documenti più vecchi o contenuti di terzi possono non rispettare tutti i criteri. Se trovi una barriera, scrivi a %{email} e cercheremo di risolverla.</p>
    HTML
  },
  "pt" => {
    terms: <<~HTML,
      <h2>O que é o PCMarket</h2>
      <p>O PCMarket é um mercado online que liga compradores e vendedores de hardware e acessórios de PC. O PCMarket não é o vendedor nem parte do contrato de compra e venda: atua como intermediário tecnológico e de pagamento.</p>
      <h2>Obrigações das partes</h2>
      <p>O comprador compromete-se a fornecer dados verdadeiros, pagar o preço e inspecionar o artigo na entrega. O vendedor compromete-se a descrever o artigo com exatidão, provar que pode vendê-lo, enviá-lo no prazo indicado e respeitar os direitos do consumidor.</p>
      <h2>Preços, pagamentos e comissões</h2>
      <p>Os preços são apresentados em euros, com os impostos aplicáveis. O pagamento é feito na plataforma através da Stripe e fica retido até a proteção do comprador estar concluída. As comissões em vigor são publicadas na página de tarifas.</p>
      <h2>Artigos proibidos</h2>
      <p>Não podem ser publicados artigos ilegais, roubados, falsificados, perigosos ou que violem direitos de terceiros. O PCMarket pode retirar anúncios e suspender contas.</p>
      <h2>Ocorrências e litígios</h2>
      <p>As ocorrências são tratadas a partir da encomenda. %{consumer_law} protege os consumidores. Qualquer litígio será apreciado por %{courts}. %{odr_note}</p>
      <h2>Lei aplicável</h2>
      <p>Estes termos regem-se pela lei de %{country}. %{local_note}</p>
    HTML
    privacy: <<~HTML,
      <h2>Responsável pelo tratamento</h2>
      <p>O responsável é %{company}, com sede em %{address} e email %{email}. Os dados de registo constam no aviso legal.</p>
      <h2>Dados tratados</h2>
      <ul><li>Identificação e contacto: nome, utilizador, email, telefone e morada.</li><li>Atividade: anúncios, mensagens, favoritos, compras e avaliações.</li><li>Pagamentos: montantes, estado e referências Stripe; não guardamos números de cartão.</li><li>Dados técnicos: IP, dispositivo, idioma e cookies.</li></ul>
      <h2>Finalidades e bases jurídicas</h2>
      <p>Tratamos os dados para executar o contrato (conta, venda e pagamentos), cumprir obrigações legais (faturação e prevenção de fraude), prosseguir interesses legítimos (segurança e melhoria do serviço) e, com o teu consentimento, enviar comunicações comerciais.</p>
      <h2>Conservação e destinatários</h2>
      <p>Conservamos os dados durante a relação e os prazos legais. Os destinatários são a Stripe (pagamentos), os fornecedores de alojamento e email e as autoridades quando exigido. Não vendemos dados pessoais.</p>
      <h2>Transferências internacionais</h2>
      <p>Se um fornecedor tratar dados fora do EEE, aplica garantias adequadas, como as cláusulas contratuais-tipo da Comissão Europeia.</p>
      <h2>Direitos</h2>
      <p>Podes pedir acesso, retificação, apagamento, oposição, limitação e portabilidade escrevendo para %{email}. Podes também reclamar junto de %{authority}. %{local_note}</p>
      <h2>Cookies</h2>
      <p>O uso de cookies é explicado na <a href="%{cookies_path}">política de cookies</a>.</p>
    HTML
    cookies: <<~HTML,
      <h2>O que são cookies</h2>
      <p>Cookies e armazenamento local permitem recordar a sessão, as preferências e, com autorização, medir o uso do site. Não usamos cookies não essenciais antes do consentimento.</p>
      <h2>Categorias</h2>
      <ul><li>Necessários: fazem o site funcionar e não podem ser desativados.</li><li>Preferências: recordam idioma, país e tema.</li><li>Análise: medem visitas e páginas usadas.</li><li>Marketing: medem campanhas e permitem publicidade relevante.</li></ul>
      <h2>Cookies que usamos</h2>
      <table><thead><tr><th>Nome</th><th>Finalidade</th><th>Duração</th><th>Categoria</th></tr></thead><tbody><tr><td>pcmarket_session</td><td>Sessão e segurança</td><td>Sessão</td><td>Necessário</td></tr><tr><td>locale</td><td>Idioma escolhido</td><td>1 ano</td><td>Preferências</td></tr><tr><td>country</td><td>País para conteúdo legal</td><td>1 ano</td><td>Preferências</td></tr><tr><td>cookie_consent</td><td>Guarda a tua escolha</td><td>6 meses</td><td>Necessário</td></tr><tr><td>theme (localStorage)</td><td>Tema claro ou escuro</td><td>Persistente</td><td>Preferências</td></tr><tr><td>__stripe_mid / __stripe_sid</td><td>Prevenção de fraude nos pagamentos</td><td>1 ano / sessão</td><td>Necessário</td></tr></tbody></table>
      <h2>Gestão</h2>
      <p>Podes alterar a escolha em «Preferências de cookies» no rodapé. Também podes apagar ou bloquear cookies no navegador, mas algumas funções deixarão de funcionar.</p>
    HTML
    legal_notice: <<~HTML,
      <h2>Titular do site</h2>
      <p>%{company}, NIF %{tax_id}, sede em %{address}, email %{email}. Dados de registo: %{registry}.</p>
      <h2>Objeto</h2>
      <p>Este site presta um serviço de intermediação entre compradores e vendedores de hardware. A informação é prestada ao abrigo de %{company_law} e da legislação aplicável ao comércio eletrónico.</p>
      <h2>Propriedade intelectual</h2>
      <p>A marca, o design, os textos e o código pertencem ao %{company} ou aos seus licenciantes. A reprodução não autorizada é proibida, salvo usos legais.</p>
      <h2>Responsabilidade</h2>
      <p>O PCMarket zela pela disponibilidade e segurança, mas não responde pelos conteúdos dos utilizadores nem pelos acordos entre as partes, sem prejuízo da proteção do comprador.</p>
      <h2>Ligações</h2>
      <p>As ligações externas são fornecidas como referência. Não controlamos o seu conteúdo nem assumimos responsabilidade. %{local_note}</p>
    HTML
    returns: <<~HTML,
      <h2>Compras a vendedores profissionais</h2>
      <p>Se comprares a um vendedor profissional, %{consumer_law} confere-te 14 dias de calendário para livre resolução, salvo exceções legais (bens personalizados, selos de higiene abertos ou conteúdos digitais descarregados). Não precisas de justificar.</p>
      <h2>Compras entre particulares</h2>
      <p>Entre particulares não existe direito legal de livre resolução. A proteção do comprador cobre, ainda assim, artigos que não cheguem, cheguem danificados ou não correspondam à descrição.</p>
      <h2>Garantia legal</h2>
      <p>Os bens novos comprados a profissionais têm 3 anos de garantia legal; os usados, pelo menos 1 ano desde a entrega. A garantia cobre a falta de conformidade, não o desgaste normal.</p>
      <h2>Como pedir uma devolução</h2>
      <p>Abre uma ocorrência na encomenda ou escreve para %{email} antes do prazo. O reembolso é feito no mesmo método de pagamento no prazo de 14 dias após a aceitação.</p>
      <h2>Formulário de livre resolução</h2>
      <p>Para %{company}, %{address}, %{email}: «Pela presente comunico que resolvo o contrato de compra e venda do seguinte bem: [DESCRIÇÃO], encomendado a [DATA] e recebido a [DATA]. Nome: [NOME]. Morada: [MORADA]. Data: [DATA].»</p>
    HTML
    seller_terms: <<~HTML,
      <h2>Quem pode vender</h2>
      <p>Tens de ser maior de idade, ter uma conta confirmada e uma loja com dados verdadeiros. Os vendedores profissionais devem indicar a identidade fiscal e cumprir os deveres de informação ao consumidor.</p>
      <h2>Regras dos anúncios</h2>
      <p>Os anúncios devem descrever o produto real, o estado e os acessórios incluídos. Só podes vender bens de que sejas proprietário ou estejas autorizado a vender, com fotos próprias.</p>
      <h2>Preços, impostos e envios</h2>
      <p>Os preços devem incluir os impostos aplicáveis. O vendedor é responsável pela faturação, pela escolha de transporte adequado e pelo cumprimento do prazo de entrega.</p>
      <h2>Pagamentos e comissões</h2>
      <p>Os pagamentos são recebidos através da plataforma. As comissões em vigor são publicadas na página de tarifas. O não pagamento pode limitar a conta.</p>
      <h2>Suspensão e responsabilidade</h2>
      <p>O PCMarket pode retirar anúncios ou suspender contas que violem estes termos. O vendedor responde pelos seus anúncios, vendas, impostos e pelo respeito dos direitos do consumidor.</p>
    HTML
    buyer_protection: <<~HTML,
      <h2>O que cobre</h2>
      <p>A proteção cobre compras pagas no PCMarket quando o artigo não chega, chega danificado, é diferente da descrição, é falsificado ou o vendedor cancela depois do pagamento.</p>
      <h2>O que não cobre</h2>
      <p>Não cobre pagamentos fora da plataforma, artigos proibidos, danos não comunicados a tempo, livre resolução entre particulares ou desgaste normal.</p>
      <h2>Como funciona</h2>
      <p>Retemos o pagamento, o vendedor envia com seguimento e tu inspecionas o artigo durante %{days} dias. Se houver um problema, abre uma ocorrência antes do fim do prazo.</p>
      <h2>Resolução e reembolsos</h2>
      <p>Analisamos a ocorrência e pedimos informação a ambas as partes. Se for aceite, reembolsamos o método de pagamento original e podemos recuperar o montante do vendedor. As decisões são fundamentadas.</p>
      <h2>Limites</h2>
      <p>A proteção é um serviço da plataforma e não substitui os direitos legais conferidos por %{consumer_law}.</p>
    HTML
    dsa_transparency: <<~HTML,
      <h2>Ponto de contacto</h2>
      <p>Para comunicações sobre o Regulamento (UE) 2022/2065 (DSA), escreve para %{email}. Respondemos em português e inglês.</p>
      <h2>Notificação e ação</h2>
      <p>Qualquer pessoa pode denunciar conteúdos alegadamente ilegais através do botão de denúncia. Confirmamos a receção, analisamos a denúncia e comunicamos a decisão.</p>
      <h2>Fundamentação</h2>
      <p>Quando removemos conteúdo ou suspendemos uma conta, informamos a pessoa afetada do motivo, do alcance da medida e de como recorrer.</p>
      <h2>Rastreabilidade dos comerciantes</h2>
      <p>Os vendedores profissionais devem fornecer identidade, dados fiscais e contacto. Estes dados aparecem no anúncio quando a lei o exige.</p>
      <h2>Resolução de litígios</h2>
      <p>As partes podem recorrer a entidades de resolução alternativa de litígios e aos tribunais. %{odr_note}</p>
      <h2>Transparência</h2>
      <p>Publicamos informação agregada sobre denúncias recebidas, medidas adotadas e prazos de resposta nos relatórios periódicos. %{dsa_note}</p>
    HTML
    prohibited_items: <<~HTML,
      <h2>Artigos proibidos</h2>
      <p>Não podem ser publicados produtos ilegais, roubados, falsificados ou que violem direitos de propriedade intelectual. Também são proibidos artigos perigosos ou regulados sem autorização.</p>
      <h2>Lista indicativa</h2>
      <ul><li>Armas, munições e réplicas proibidas.</li><li>Drogas, substâncias controladas e precursores.</li><li>Material de abuso de menores ou conteúdo ilegal.</li><li>Dados pessoais, contas e credenciais.</li><li>Software malicioso, licenças ilegais e ferramentas de fraude.</li><li>Baterias danificadas ou componentes eletricamente inseguros.</li><li>Produtos recolhidos por segurança.</li><li>Bens roubados ou de origem não comprovada.</li></ul>
      <h2>Consequências</h2>
      <p>Retiramos os anúncios, podemos suspender a conta e, quando aplicável, informamos as autoridades. Em caso de dúvida, pergunta antes de publicar.</p>
    HTML
    fees: <<~HTML,
      <h2>Publicar é grátis</h2>
      <p>Durante a fase de crescimento, publicar e vender não tem comissão. Não há mensalidade nem custo por carregar fotos.</p>
      <h2>Comissão futura</h2>
      <p>Se ativarmos uma comissão, será anunciada com antecedência, mostrada antes da publicação e aplicada apenas a novas vendas. É calculada sobre o subtotal do artigo, sem o envio.</p>
      <h2>Anúncios em destaque</h2>
      <p>Destacar um anúncio é opcional. O preço é mostrado antes da contratação e nunca é cobrado automaticamente.</p>
      <h2>Impostos</h2>
      <p>Os preços incluem o IVA aplicável. Cada vendedor é responsável pelas suas obrigações fiscais. %{local_note}</p>
    HTML
    accessibility: <<~HTML
      <h2>O nosso compromisso</h2>
      <p>Queremos que o PCMarket seja utilizável pelo maior número de pessoas possível. Trabalhamos para cumprir as WCAG 2.1 nível AA nas páginas principais.</p>
      <h2>Medidas</h2>
      <ul><li>Navegação por teclado e foco visível.</li><li>Contrastes verificados em tema claro e escuro.</li><li>Textos alternativos e etiquetas acessíveis.</li><li>Respeito pela preferência de movimento reduzido.</li></ul>
      <h2>Limitações e contacto</h2>
      <p>Documentos antigos ou conteúdos de terceiros podem não cumprir todos os critérios. Se encontrares uma barreira, escreve para %{email} e tentaremos resolvê-la.</p>
    HTML
  }
}.freeze

legal_profiles = [
  {
    code: "ES",
    locales: %w[es en fr de it pt],
    published: true,
    values: {
      "es" => {
        country: "España",
        authority: "la Agencia Española de Protección de Datos (AEPD)",
        consumer_law: "El Real Decreto Legislativo 1/2007 (Ley General para la Defensa de los Consumidores y Usuarios)",
        company_law: "la Ley 34/2002 de Servicios de la Sociedad de la Información (LSSI-CE)",
        courts: "los juzgados y tribunales del domicilio del consumidor",
        local_note: "Se aplican el RGPD y la Ley Orgánica 3/2018 (LOPDGDD).",
        odr_note: "Puedes usar la plataforma europea de resolución de litigios en línea: https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket cumple el Reglamento (UE) 2022/2065 de Servicios Digitales (DSA).",
        company: "[NOMBRE DE LA EMPRESA]",
        tax_id: "[NIF]",
        address: "[DOMICILIO COMPLETO]",
        registry: "[DATOS REGISTRALES]",
        email: "[CORREO DE CONTACTO]"
      },
      "en" => {
        country: "Spain",
        authority: "the Spanish Data Protection Agency (AEPD)",
        consumer_law: "Royal Legislative Decree 1/2007 (Spanish Consumer Protection Act)",
        company_law: "Law 34/2002 on Information Society Services (LSSI-CE)",
        courts: "the courts of the consumer's domicile",
        local_note: "The GDPR and Organic Law 3/2018 (LOPDGDD) apply.",
        odr_note: "You can use the European online dispute resolution platform: https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket complies with Regulation (EU) 2022/2065 on Digital Services (DSA).",
        company: "[COMPANY NAME]",
        tax_id: "[TAX ID]",
        address: "[FULL ADDRESS]",
        registry: "[REGISTRY DETAILS]",
        email: "[CONTACT EMAIL]"
      },
      "fr" => {
        country: "Espagne",
        authority: "l'Agence espagnole de protection des données (AEPD)",
        consumer_law: "le décret législatif royal 1/2007 (loi espagnole de protection des consommateurs)",
        company_law: "la loi 34/2002 sur les services de la société de l'information (LSSI-CE)",
        courts: "les tribunaux du domicile du consommateur",
        local_note: "Le RGPD et la loi organique 3/2018 (LOPDGDD) s'appliquent.",
        odr_note: "Vous pouvez utiliser la plateforme européenne de règlement en ligne des litiges : https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket respecte le règlement (UE) 2022/2065 sur les services numériques (DSA).",
        company: "[NOM DE LA SOCIÉTÉ]",
        tax_id: "[IDENTIFIANT FISCAL]",
        address: "[ADRESSE COMPLÈTE]",
        registry: "[DONNÉES D'IMMATRICULATION]",
        email: "[COURRIEL DE CONTACT]"
      },
      "de" => {
        country: "Spanien",
        authority: "die spanische Datenschutzbehörde (AEPD)",
        consumer_law: "das Königliche Gesetzesdekret 1/2007 (spanisches Verbraucherschutzgesetz)",
        company_law: "das Gesetz 34/2002 über Dienste der Informationsgesellschaft (LSSI-CE)",
        courts: "die Gerichte am Wohnsitz des Verbrauchers",
        local_note: "Es gelten die DSGVO und das spanische Organgesetz 3/2018 (LOPDGDD).",
        odr_note: "Du kannst die europäische Plattform zur Online-Streitbeilegung nutzen: https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket erfüllt die Verordnung (EU) 2022/2065 über digitale Dienste (DSA).",
        company: "[FIRMENNAME]",
        tax_id: "[STEUER-ID]",
        address: "[VOLLSTÄNDIGE ANSCHRIFT]",
        registry: "[REGISTERDATEN]",
        email: "[KONTAKT-E-MAIL]"
      },
      "it" => {
        country: "Spagna",
        authority: "l'Agenzia spagnola per la protezione dei dati (AEPD)",
        consumer_law: "il Regio Decreto Legislativo 1/2007 (legge spagnola a tutela dei consumatori)",
        company_law: "la legge 34/2002 sui servizi della società dell'informazione (LSSI-CE)",
        courts: "i tribunali del domicilio del consumatore",
        local_note: "Si applicano il GDPR e la legge organica 3/2018 (LOPDGDD).",
        odr_note: "Puoi usare la piattaforma europea di risoluzione online delle controversie: https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket rispetta il Regolamento (UE) 2022/2065 sui servizi digitali (DSA).",
        company: "[NOME DELLA SOCIETÀ]",
        tax_id: "[P.IVA]",
        address: "[INDIRIZZO COMPLETO]",
        registry: "[DATI DI REGISTRAZIONE]",
        email: "[EMAIL DI CONTATTO]"
      },
      "pt" => {
        country: "Espanha",
        authority: "a Agência Espanhola de Proteção de Dados (AEPD)",
        consumer_law: "o Real Decreto Legislativo 1/2007 (lei espanhola de defesa do consumidor)",
        company_law: "a Lei 34/2002 dos Serviços da Sociedade da Informação (LSSI-CE)",
        courts: "os tribunais do domicílio do consumidor",
        local_note: "Aplicam-se o RGPD e a Lei Orgânica 3/2018 (LOPDGDD).",
        odr_note: "Podes usar a plataforma europeia de resolução de litígios em linha: https://ec.europa.eu/consumers/odr.",
        dsa_note: "O PCMarket cumpre o Regulamento (UE) 2022/2065 dos Serviços Digitais (DSA).",
        company: "[NOME DA EMPRESA]",
        tax_id: "[NIF]",
        address: "[MORADA COMPLETA]",
        registry: "[DADOS DE REGISTO]",
        email: "[EMAIL DE CONTACTO]"
      }
    }
  },
  {
    code: "FR",
    locales: %w[fr en],
    published: false,
    values: {
      "fr" => {
        country: "France",
        authority: "la Commission nationale de l'informatique et des libertés (CNIL)",
        consumer_law: "le Code de la consommation",
        company_law: "la loi pour la confiance dans l'économie numérique (LCEN)",
        courts: "les tribunaux français compétents",
        local_note: "Le médiateur de la consommation compétent est [MÉDIATEUR]. Le droit français de la consommation s'applique.",
        odr_note: "Vous pouvez utiliser la plateforme européenne de règlement en ligne des litiges : https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket respecte le règlement (UE) 2022/2065 sur les services numériques (DSA).",
        company: "[NOM DE LA SOCIÉTÉ]",
        tax_id: "[NUMÉRO SIREN]",
        address: "[ADRESSE COMPLÈTE]",
        registry: "[RCS]",
        email: "[COURRIEL DE CONTACT]"
      },
      "en" => {
        country: "France",
        authority: "the French data protection authority (CNIL)",
        consumer_law: "the French Consumer Code",
        company_law: "the Law on Confidence in the Digital Economy (LCEN)",
        courts: "the competent French courts",
        local_note: "The competent consumer mediator is [MEDIATOR]. French consumer law applies.",
        odr_note: "You can use the European online dispute resolution platform: https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket complies with Regulation (EU) 2022/2065 on Digital Services (DSA).",
        company: "[COMPANY NAME]",
        tax_id: "[SIREN NUMBER]",
        address: "[FULL ADDRESS]",
        registry: "[TRADE REGISTER]",
        email: "[CONTACT EMAIL]"
      }
    }
  },
  {
    code: "GB",
    locales: %w[en],
    published: false,
    values: {
      "en" => {
        country: "the United Kingdom",
        authority: "the Information Commissioner's Office (ICO)",
        consumer_law: "the Consumer Rights Act 2015 and the Consumer Contracts (Information, Cancellation and Additional Charges) Regulations 2013",
        company_law: "the Companies Act 2006",
        courts: "the courts of England and Wales",
        local_note: "The UK GDPR and the Data Protection Act 2018 apply. Company details are provided under the Companies Act 2006.",
        odr_note: "",
        dsa_note: "The EU Digital Services Act does not apply in Great Britain. This page is retained for transparency and describes the equivalent notice-and-action commitments.",
        company: "[COMPANY NAME]",
        tax_id: "[COMPANY NUMBER]",
        address: "[REGISTERED OFFICE ADDRESS]",
        registry: "[PLACE OF REGISTRATION]",
        email: "[CONTACT EMAIL]"
      }
    }
  },
  {
    code: "DE",
    locales: %w[de en],
    published: false,
    values: {
      "de" => {
        country: "Deutschland",
        authority: "die zuständige Datenschutzaufsichtsbehörde",
        consumer_law: "das Bürgerliche Gesetzbuch (BGB)",
        company_law: "§ 5 des Digitale-Dienste-Gesetzes (DDG)",
        courts: "die zuständigen deutschen Gerichte",
        local_note: "Es gelten die DSGVO und das BDSG. Verbraucherstreitbeilegung nach VSBG: [STREITBEILEGUNGSSTELLE].",
        odr_note: "Du kannst die europäische Plattform zur Online-Streitbeilegung nutzen: https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket erfüllt die Verordnung (EU) 2022/2065 über digitale Dienste (DSA).",
        company: "[FIRMENNAME]",
        tax_id: "[UST-IDNR.]",
        address: "[VOLLSTÄNDIGE ANSCHRIFT]",
        registry: "[HANDELSREGISTER]",
        email: "[KONTAKT-E-MAIL]"
      },
      "en" => {
        country: "Germany",
        authority: "the competent German data protection authority",
        consumer_law: "the German Civil Code (BGB)",
        company_law: "section 5 of the Digital Services Act (DDG)",
        courts: "the competent German courts",
        local_note: "The GDPR and the BDSG apply. Consumer dispute resolution under the VSBG: [DISPUTE RESOLUTION BODY].",
        odr_note: "You can use the European online dispute resolution platform: https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket complies with Regulation (EU) 2022/2065 on Digital Services (DSA).",
        company: "[COMPANY NAME]",
        tax_id: "[VAT ID]",
        address: "[FULL ADDRESS]",
        registry: "[COMMERCIAL REGISTER]",
        email: "[CONTACT EMAIL]"
      }
    }
  },
  {
    code: "IT",
    locales: %w[it en],
    published: false,
    values: {
      "it" => {
        country: "Italia",
        authority: "il Garante per la protezione dei dati personali",
        consumer_law: "il Codice del Consumo (D.Lgs. 206/2005)",
        company_law: "l'art. 7 del D.Lgs. 70/2003 sul commercio elettronico",
        courts: "i tribunali italiani competenti",
        local_note: "Si applicano il GDPR e il Codice in materia di protezione dei dati personali. P.IVA [PARTITA IVA].",
        odr_note: "Puoi usare la piattaforma europea di risoluzione online delle controversie: https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket rispetta il Regolamento (UE) 2022/2065 sui servizi digitali (DSA).",
        company: "[NOME DELLA SOCIETÀ]",
        tax_id: "[PARTITA IVA]",
        address: "[INDIRIZZO COMPLETO]",
        registry: "[REGISTRO IMPRESE]",
        email: "[EMAIL DI CONTATTO]"
      },
      "en" => {
        country: "Italy",
        authority: "the Italian data protection authority (Garante Privacy)",
        consumer_law: "the Italian Consumer Code (Legislative Decree 206/2005)",
        company_law: "article 7 of Legislative Decree 70/2003 on e-commerce",
        courts: "the competent Italian courts",
        local_note: "The GDPR and the Italian Data Protection Code apply. VAT number [VAT NUMBER].",
        odr_note: "You can use the European online dispute resolution platform: https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket complies with Regulation (EU) 2022/2065 on Digital Services (DSA).",
        company: "[COMPANY NAME]",
        tax_id: "[VAT NUMBER]",
        address: "[FULL ADDRESS]",
        registry: "[BUSINESS REGISTER]",
        email: "[CONTACT EMAIL]"
      }
    }
  },
  {
    code: "PT",
    locales: %w[pt en],
    published: false,
    values: {
      "pt" => {
        country: "Portugal",
        authority: "a Comissão Nacional de Proteção de Dados (CNPD)",
        consumer_law: "a Lei n.º 24/96 de defesa do consumidor",
        company_law: "o Decreto-Lei n.º 7/2004 sobre comércio eletrónico",
        courts: "os tribunais portugueses competentes",
        local_note: "Aplicam-se o RGPD e a Lei n.º 58/2019. Reclamações: Livro de Reclamações Eletrónico (https://www.livroreclamacoes.pt).",
        odr_note: "Podes usar a plataforma europeia de resolução de litígios em linha: https://ec.europa.eu/consumers/odr.",
        dsa_note: "O PCMarket cumpre o Regulamento (UE) 2022/2065 dos Serviços Digitais (DSA).",
        company: "[NOME DA EMPRESA]",
        tax_id: "[NIF]",
        address: "[MORADA COMPLETA]",
        registry: "[REGISTO COMERCIAL]",
        email: "[EMAIL DE CONTACTO]"
      },
      "en" => {
        country: "Portugal",
        authority: "the Portuguese Data Protection Commission (CNPD)",
        consumer_law: "Law 24/96 on consumer protection",
        company_law: "Decree-Law 7/2004 on e-commerce",
        courts: "the competent Portuguese courts",
        local_note: "The GDPR and Law 58/2019 apply. Complaints: Electronic Complaints Book (https://www.livroreclamacoes.pt).",
        odr_note: "You can use the European online dispute resolution platform: https://ec.europa.eu/consumers/odr.",
        dsa_note: "PCMarket complies with Regulation (EU) 2022/2065 on Digital Services (DSA).",
        company: "[COMPANY NAME]",
        tax_id: "[TAX ID]",
        address: "[FULL ADDRESS]",
        registry: "[COMMERCIAL REGISTER]",
        email: "[CONTACT EMAIL]"
      }
    }
  }
]

render_legal_body = lambda do |template, values|
  template.gsub(/%\{(\w+)\}/) { values.fetch(Regexp.last_match(1), "") }
end

legal_profiles.each do |profile|
  profile[:locales].each do |locale|
    values = profile[:values].fetch(locale).merge(
      "cookies_path" => "/#{locale}/legal/cookies"
    )
    titles = legal_titles.fetch(locale)
    documents = legal_documents.fetch(locale)

    LegalPage::KINDS.each do |kind|
      template = documents.fetch(kind.to_sym)
      body = render_legal_body.call(template, values)

      page = LegalPage.find_or_initialize_by(
        country_code: profile[:code],
        locale: locale,
        kind: kind,
        version: "1.0"
      )

      page.title = titles.fetch(kind.to_sym)
      page.review_required = true
      page.status = profile[:published] ? :published : :draft

      if profile[:published]
        page.published_at ||= Time.zone.local(2026, 11, 1, 9)
        page.effective_at ||= page.published_at
      end

      page.body = body
      page.save!
    end
  end
end
