const products = [
  {id:1, code:'740000001101', name:'Pastillas de freno RX', category:'Frenos', type:'moto', compat:'Yamaha YBR / Suzuki GN', stock:2, min:8, cost:42, price:75, icon:'⚙'},
  {id:2, code:'740000001102', name:'Filtro de aceite 15410', category:'Motor', type:'moto', compat:'Honda CB / XR', stock:5, min:10, cost:27, price:55, icon:'◈'},
  {id:3, code:'740000001103', name:'Cable clutch universal', category:'Transmisión', type:'tuctuc', compat:'TVS King / Bajaj RE', stock:7, min:12, cost:25, price:55, icon:'⌁'},
  {id:4, code:'740000001104', name:'Bombillo LED H4 12V', category:'Eléctrico', type:'auto', compat:'Universal / Toyota', stock:24, min:6, cost:48, price:80, icon:'✦'},
  {id:5, code:'740000001105', name:'Kit cadena + sprocket', category:'Transmisión', type:'moto', compat:'Honda CG / Yamaha YBR', stock:12, min:5, cost:138, price:225, icon:'◎'},
  {id:6, code:'740000001106', name:'Zapatas traseras Bajaj', category:'Frenos', type:'tuctuc', compat:'Bajaj RE 4S', stock:18, min:8, cost:62, price:110, icon:'◌'},
  {id:7, code:'740000001107', name:'Bujía NGK C7HSA', category:'Motor', type:'moto', compat:'Moto / Tuc tuc', stock:36, min:15, cost:14, price:28, icon:'⌁'},
  {id:8, code:'740000001108', name:'Filtro aire Corolla', category:'Motor', type:'auto', compat:'Toyota Corolla 2009–2019', stock:9, min:5, cost:55, price:95, icon:'◇'},
  {id:9, code:'740000001109', name:'Retenedor de llanta TVS', category:'Suspensión', type:'tuctuc', compat:'TVS King 2018–2026', stock:15, min:6, cost:18, price:38, icon:'◉'}
];

let cart = JSON.parse(localStorage.getItem('repuestos-demo-cart') || '[]');
let currentType = 'all';
let currentMethod = 'Efectivo';
let scannerStream = null;
let scanInterval = null;

const $ = s => document.querySelector(s);
const $$ = s => [...document.querySelectorAll(s)];
const money = n => `Q ${Number(n).toFixed(2)}`;

const titles = {
  dashboard:'Resumen del negocio', sale:'Nueva venta', inventory:'Inventario', purchases:'Compras y proveedores', expenses:'Gastos', customers:'Clientes', cash:'Control de caja', reports:'Reportes', settings:'Configuración'
};

function navigate(view){
  $$('.view').forEach(v => v.classList.remove('active'));
  $(`#${view}-view`)?.classList.add('active');
  $$('.nav-item[data-view], .mobile-nav-item[data-view]').forEach(b => b.classList.toggle('active', b.dataset.view===view));
  $('#pageTitle').textContent = titles[view] || 'Repuestos POS';
  $('#sidebar').classList.remove('open');
  window.scrollTo({top:0,behavior:'smooth'});
  if(view==='sale') setTimeout(()=>$('#scanInput')?.focus(),150);
}

$$('[data-view]').forEach(b => b.addEventListener('click',()=>navigate(b.dataset.view)));
$$('[data-view-link]').forEach(b => b.addEventListener('click',()=>navigate(b.dataset.viewLink)));
$$('[data-open-sale]').forEach(b => b.addEventListener('click',()=>navigate('sale')));
$('#menuBtn').addEventListener('click',()=>$('#sidebar').classList.toggle('open'));
$('#moreMobile').addEventListener('click',()=>$('#sidebar').classList.toggle('open'));

function renderProducts(){
  const q = ($('#scanInput').value || '').trim().toLowerCase();
  const filtered = products.filter(p => (currentType==='all'||p.type===currentType) && (!q || [p.name,p.code,p.compat,p.category].join(' ').toLowerCase().includes(q)));
  $('#productGrid').innerHTML = filtered.map(p=>`
    <article class="product-card">
      <div class="product-top"><div class="product-visual">${p.icon}</div><span class="stock-pill ${p.stock<=p.min?'low':''}">${p.stock} uds.</span></div>
      <h3>${p.name}</h3><p>${p.compat}</p>
      <div class="product-bottom"><strong>${money(p.price)}</strong><button data-add="${p.id}" aria-label="Agregar ${p.name}">+</button></div>
    </article>`).join('') || `<div class="panel" style="padding:28px;grid-column:1/-1;text-align:center;color:#84909f;font-size:11px">No se encontraron productos.</div>`;
  $$('[data-add]').forEach(btn=>btn.addEventListener('click',()=>addToCart(Number(btn.dataset.add))));
}

function renderInventory(){
  $('#inventoryBody').innerHTML = products.map(p=>{
    const state = p.stock===0?['Agotado','danger']:p.stock<=p.min?['Bajo','pending']:['Normal','success'];
    const ratio = Math.min(100,(p.stock/Math.max(p.min*2,1))*100);
    return `<tr><td><strong>${p.name}</strong><span>${p.category}</span></td><td>${p.code}</td><td>${p.compat}</td><td>${money(p.cost)}</td><td><strong>${money(p.price)}</strong></td><td><div class="stock-inline"><b>${p.stock}</b><i><span style="width:${ratio}%"></span></i></div></td><td><span class="pill ${state[1]}">${state[0]}</span></td><td>•••</td></tr>`;
  }).join('');
}

function addToCart(id, qty=1){
  const p = products.find(x=>x.id===id); if(!p) return;
  const item = cart.find(x=>x.id===id);
  if(item) item.qty += qty; else cart.push({id,qty});
  saveCart(); renderCart(); showToast('Producto agregado',p.name);
}
function changeQty(id,delta){
  const item = cart.find(x=>x.id===id); if(!item)return;
  item.qty += delta;
  if(item.qty<=0) cart = cart.filter(x=>x.id!==id);
  saveCart(); renderCart();
}
function saveCart(){localStorage.setItem('repuestos-demo-cart',JSON.stringify(cart));}
function getTotal(){return cart.reduce((s,i)=>{const p=products.find(x=>x.id===i.id);return s+(p?p.price*i.qty:0)},0)}
function renderCart(){
  const box=$('#cartItems');
  if(!cart.length){box.innerHTML='<div class="empty-cart"><div>▣</div><strong>Venta vacía</strong><span>Escanea un producto para comenzar.</span></div>'}
  else box.innerHTML=cart.map(i=>{const p=products.find(x=>x.id===i.id);return `<div class="cart-item"><div><h4>${p.name}</h4><small>${p.code}</small><div class="qty-controls"><button data-qty="${p.id}" data-delta="-1">−</button><span>${i.qty}</span><button data-qty="${p.id}" data-delta="1">+</button></div></div><div class="cart-item-price"><strong>${money(p.price*i.qty)}</strong><small>${money(p.price)} c/u</small></div></div>`}).join('');
  $$('[data-qty]').forEach(b=>b.addEventListener('click',()=>changeQty(Number(b.dataset.qty),Number(b.dataset.delta))));
  const total=getTotal();
  $('#subtotal').textContent=money(total);$('#total').textContent=money(total);$('#checkoutAmount').textContent=money(total);$('#checkoutBtn').disabled=!cart.length;
}

$('#clearCart').addEventListener('click',()=>{cart=[];saveCart();renderCart();showToast('Venta vaciada','Puedes comenzar un nuevo ticket.');});
$$('.filter-chip').forEach(b=>b.addEventListener('click',()=>{$$('.filter-chip').forEach(x=>x.classList.remove('active'));b.classList.add('active');currentType=b.dataset.filter;renderProducts();}));
$('#scanInput').addEventListener('input',renderProducts);
$('#scanInput').addEventListener('keydown',e=>{
  if(e.key==='Enter'){
    const raw=e.target.value.trim();
    const p=products.find(x=>x.code===raw) || products.find(x=>x.name.toLowerCase().includes(raw.toLowerCase()));
    if(p){addToCart(p.id);e.target.value='';renderProducts();} else if(raw) showToast('Código no encontrado','Puedes crear un producto nuevo desde Inventario.',true);
  }
});

function openModal(id){$(id).classList.add('open')}
function closeModals(){ $$('.modal-backdrop').forEach(m=>m.classList.remove('open')); stopScanner(); }
$$('[data-close-modal]').forEach(b=>b.addEventListener('click',closeModals));
$$('.modal-backdrop').forEach(m=>m.addEventListener('click',e=>{if(e.target===m)closeModals()}));

$('#checkoutBtn').addEventListener('click',()=>{
  $('#modalTotal').textContent=money(getTotal()); $('#receivedInput').value=''; $('#changeAmount').textContent='Q 0.00'; openModal('#paymentModal'); setTimeout(()=>$('#receivedInput').focus(),120);
});
$$('.pay-method').forEach(b=>b.addEventListener('click',()=>{$$('.pay-method').forEach(x=>x.classList.remove('active'));b.classList.add('active');currentMethod=b.dataset.method;}));
$('#receivedInput').addEventListener('input',e=>{const change=Math.max(0,(parseFloat(e.target.value)||0)-getTotal());$('#changeAmount').textContent=money(change)});
$('#confirmPayment').addEventListener('click',()=>{
  if(!cart.length)return;
  const total=getTotal(); const ticket=`V-${1029+Math.floor(Math.random()*30)}`;
  cart=[];saveCart();renderCart();closeModals();showToast('Venta completada',`${ticket} · ${currentMethod} · ${money(total)}`);navigate('dashboard');
});

$('#cameraBtn').addEventListener('click',()=>{openModal('#scannerModal');startScanner();});
async function startScanner(){
  const placeholder=$('#cameraPlaceholder'),video=$('#scannerVideo'),help=$('#scannerHelp');
  try{
    if(!navigator.mediaDevices?.getUserMedia) throw new Error('camera');
    scannerStream=await navigator.mediaDevices.getUserMedia({video:{facingMode:{ideal:'environment'}},audio:false});
    video.srcObject=scannerStream; await video.play(); placeholder.style.display='none';
    if('BarcodeDetector' in window){
      const formats=await BarcodeDetector.getSupportedFormats(); const detector=new BarcodeDetector({formats:formats.filter(f=>['qr_code','code_128','ean_13','ean_8','upc_a','upc_e'].includes(f))});
      scanInterval=setInterval(async()=>{try{const codes=await detector.detect(video);if(codes[0]?.rawValue){const raw=codes[0].rawValue;const p=products.find(x=>x.code===raw);stopScanner();closeModals();navigate('sale');if(p)addToCart(p.id);else{$('#scanInput').value=raw;renderProducts();showToast('Código leído','No existe en el catálogo; revisa el código.',true)}}}catch{}},700);
      help.textContent='Cámara activa. Mantén el código dentro del recuadro.';
    }else help.textContent='Cámara activa. Este navegador no incluye BarcodeDetector; usa un lector USB/Bluetooth o escribe el código manualmente.';
  }catch(err){placeholder.innerHTML='▥<span>No fue posible iniciar la cámara</span>';help.textContent='Revisa el permiso de cámara. El lector físico USB/Bluetooth seguirá funcionando desde el campo de venta.';}
}
function stopScanner(){if(scanInterval){clearInterval(scanInterval);scanInterval=null}if(scannerStream){scannerStream.getTracks().forEach(t=>t.stop());scannerStream=null}const p=$('#cameraPlaceholder');if(p){p.style.display='flex';p.innerHTML='▥<span>Preparando cámara…</span>';}}

function showToast(title,text,isError=false){
  $('#toastTitle').textContent=title;$('#toastText').textContent=text;$('#toast').querySelector('.toast-icon').textContent=isError?'!':'✓';$('#toast').classList.add('show');clearTimeout(window.__toast);window.__toast=setTimeout(()=>$('#toast').classList.remove('show'),2600);
}

$('#addProductBtn')?.addEventListener('click',()=>showToast('Prototipo','Aquí se abriría el formulario de alta de producto.'));
$('#addExpenseBtn')?.addEventListener('click',()=>showToast('Prototipo','Aquí se registraría un nuevo gasto.'));
$('#closeCashBtn')?.addEventListener('click',()=>showToast('Corte de caja','Se abriría el conteo físico y conciliación del turno.'));

window.addEventListener('keydown',e=>{
  if(e.key==='F1'){e.preventDefault();navigate('sale')}
  if(e.key==='F4'){e.preventDefault();navigate('inventory')}
  if(e.key==='F2' && $('#sale-view').classList.contains('active') && cart.length){e.preventDefault();$('#checkoutBtn').click()}
});

renderProducts();renderInventory();renderCart();
if('serviceWorker' in navigator){window.addEventListener('load',()=>navigator.serviceWorker.register('./service-worker.js').catch(()=>{}))}
