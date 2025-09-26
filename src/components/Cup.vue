<template>
  <div>
    <canvas ref="canvas"></canvas>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref, reactive } from 'vue';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import { Pane } from 'tweakpane';

const canvas = ref<HTMLCanvasElement | null>(null);

let camera: any;
let renderer: any;
let controls: any;
let pane: Pane | null = null;

const cupSizes = reactive({
  // common geometrical parameters
  height: 4.5,
  outerRadius: 2,
  wallThickness: 0.2,
  radialSegments: 64,
  // horizontal offset of the text texture around the cup (UV.x)
  textureOffsetX: 0.52,
  // how far the liquid surface is below the top edge
  liquidOffsetFromTop: 0.55,
  // text parameters
  text: {
    title: {
      content: 'Спасибо за такое атмосферное мероприятие!',
      fontSize: 64,
      lineHeight: 72,
      color: '#0e586b',
    },
    subtitle: {
      content: 'Отличная организация, тематические локации и перформанс!',
      fontSize: 36,
      lineHeight: 44,
      color: '#0e586b',
    },
    background: '#f2e7db',
    padding: 24,
    pxPerUnit: 128, // pixels per world unit (affects canvas resolution)
  },
  // handle parameters
  handle: {
    ringRadius: 1.2,
    tubeRadius: 0.25,
    arc: Math.PI,
  },
});

const getInnerRadius = () => cupSizes.outerRadius - cupSizes.wallThickness;

const onResize = () => {
  if (!canvas.value || !renderer || !camera) {
    return;
  }
  const width = window.innerWidth;
  const height = window.innerHeight;

  // Update camera
  camera.aspect = width / height || 1;
  camera.updateProjectionMatrix();

  renderer.setSize(width, height, false);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
};

onMounted(() => {
  if (!canvas.value) {
    return;
  }
  // canvas
  const width = window.innerWidth;
  const height = window.innerHeight;

  const scene = new THREE.Scene();
  scene.background = new THREE.Color('#1f1f1f');

  camera = new THREE.PerspectiveCamera(85, width / height, 0.1, 100);
  // camera = new THREE.OrthographicCamera(
  //   width / -80,
  //   width / 80,
  //   height / 80,
  //   height / -80,
  //   1,
  //   1000,
  // );
  camera.position.set(0, 4, 7);

  renderer = new THREE.WebGLRenderer({ canvas: canvas.value, antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setSize(width, height, false);

  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  // Prevent the camera from going below the horizon relative to the target
  controls.maxPolarAngle = Math.PI / 2; // look no further down than the horizon
  // Keep panning parallel to the ground plane so Y doesn't change while panning
  controls.screenSpacePanning = false;

  // Свет для toon-материала
  const light = new THREE.DirectionalLight('#ffffff', 3);
  light.position.set(0, 4, 0);
  scene.add(light);

  // === КРУЖКА ===
  const cupGourp = new THREE.Group();

  // === создаём canvas и функции отрисовки текста ===
  const canvasText = document.createElement('canvas');
  const ctx = canvasText.getContext('2d')!;

  // Вспомогательная: расчет размеров канваса от размеров кружки
  const computeCanvasSize = () => {
    const pxPerUnit = Math.max(16, Math.floor(cupSizes.text.pxPerUnit));
    const width = Math.max(64, Math.round(2 * Math.PI * cupSizes.outerRadius * pxPerUnit)); // полный оборот
    const height = Math.max(64, Math.round(cupSizes.height * pxPerUnit));
    return { width, height };
  };

  // Перенос слов с учетом явных переносов \n
  const wrapLines = (text: string, maxWidth: number, font: string, lineHeight: number) => {
    ctx.font = font;
    const rawLines = text.split(/\n/g);
    const lines: string[] = [];
    for (const raw of rawLines) {
      const words = raw.split(/\s+/);
      let line = '';
      for (const w of words) {
        const test = line ? line + ' ' + w : w;
        const m = ctx.measureText(test).width;
        if (m <= maxWidth) {
          line = test;
        } else {
          if (line) lines.push(line);
          // Если одно слово длиннее всей строки, вынесем как отдельную строку
          if (ctx.measureText(w).width > maxWidth) {
            lines.push(w);
            line = '';
          } else {
            line = w;
          }
        }
      }
      lines.push(line);
    }
    return lines;
  };

  // Отрисовка текста по центру, в области шириной пол-оборота
  const updateCanvasTexture = () => {
    const { width, height } = computeCanvasSize();
    // При изменении размеров важно обновлять width/height до рисования — это очистит канвас
    canvasText.width = width;
    canvasText.height = height;

    // Фон кружки
    ctx.fillStyle = cupSizes.text.background;
    ctx.fillRect(0, 0, width, height);

    // Настройки текста
    const areaWidth = Math.max(10, Math.floor(width * 0.5)); // пол-оборота
    const pad = Math.max(0, Math.floor(cupSizes.text.padding));
    const contentWidth = Math.max(10, areaWidth - pad * 2);
    const areaX = Math.floor((width - areaWidth) / 2) + pad; // центр по горизонтали

    // Title metrics
    const titleFontSize = Math.max(6, Math.floor(cupSizes.text.title.fontSize));
    const titleLineHeight = Math.max(titleFontSize + 2, Math.floor(cupSizes.text.title.lineHeight));
    const titleFont = `700 ${titleFontSize}px 'Inter Tight'`;

    // Subtitle metrics
    const subtitleFontSize = Math.max(6, Math.floor(cupSizes.text.subtitle.fontSize));
    const subtitleLineHeight = Math.max(
      subtitleFontSize + 2,
      Math.floor(cupSizes.text.subtitle.lineHeight),
    );
    const subtitleFont = `600 ${subtitleFontSize}px 'Inter Tight'`;

    // Wrap lines
    const titleLines = wrapLines(
      cupSizes.text.title.content || '',
      contentWidth,
      titleFont,
      titleLineHeight,
    );
    const subtitleLines = wrapLines(
      cupSizes.text.subtitle.content || '',
      contentWidth,
      subtitleFont,
      subtitleLineHeight,
    );

    // Combined block height for vertical centering
    const totalTextHeight =
      titleLines.length * titleLineHeight + subtitleLines.length * subtitleLineHeight;
    let y = Math.floor((height - totalTextHeight) / 2);

    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';

    // Draw title
    ctx.font = titleFont;
    ctx.fillStyle = cupSizes.text.title.color;
    for (const line of titleLines) {
      ctx.fillText(line, areaX + contentWidth / 2, y);
      y += titleLineHeight;
    }

    // Draw subtitle directly under title
    ctx.font = subtitleFont;
    ctx.fillStyle = cupSizes.text.subtitle.color;
    for (const line of subtitleLines) {
      ctx.fillText(line, areaX + contentWidth / 2, y);
      y += subtitleLineHeight;
    }

    textTexture.needsUpdate = true;
  };

  // === текстура ===
  const textTexture = new THREE.CanvasTexture(canvasText);
  textTexture.needsUpdate = true;
  textTexture.wrapS = THREE.RepeatWrapping;
  textTexture.wrapT = THREE.RepeatWrapping;
  // Смещение текста по окружности
  textTexture.offset.x = cupSizes.textureOffsetX;

  // Первый рендер текста
  updateCanvasTexture();

  // === цилиндр-кружка ===
  // Весь цилиндр, но надпись будет только спереди,
  // потому что canvasText залит белым, а текст по центру
  const cupGeometry = new THREE.CylinderGeometry(
    cupSizes.outerRadius,
    cupSizes.outerRadius,
    cupSizes.height,
    cupSizes.radialSegments,
    1,
    true,
  );
  const cupMaterial = new THREE.MeshToonMaterial({
    map: textTexture,
    // emissive: '#0e586b',
  });
  const cup = new THREE.Mesh(cupGeometry, cupMaterial);
  cupGourp.add(cup);

  // Внутренняя часть кружки
  const innerGeometry = new THREE.CylinderGeometry(
    getInnerRadius(),
    getInnerRadius(),
    cupSizes.height,
    cupSizes.radialSegments,
    1,
    true,
  );
  const innerMaterial = new THREE.MeshToonMaterial({ color: '#325aaa', side: THREE.DoubleSide }); // голубая заливка
  const inner = new THREE.Mesh(innerGeometry, innerMaterial);
  inner.position.y = 0.01; // чуть выше, чтобы не было "Z-fighting"
  cupGourp.add(inner);

  // Края кружки
  const geometryCupBorder = new THREE.RingGeometry(
    getInnerRadius(),
    cupSizes.outerRadius,
    cupSizes.radialSegments,
  );
  const innerCupBorderMaterial = new THREE.MeshToonMaterial({
    color: '#62adbf',
  });
  const borderCup = new THREE.Mesh(geometryCupBorder, innerCupBorderMaterial);
  borderCup.rotation.x = -Math.PI / 2;
  borderCup.position.y = cupSizes.height / 2; // top edge
  cupGourp.add(borderCup);

  // Дно кружки (чтобы закрыть низ)
  // const bottomGeometry = new THREE.CircleGeometry(1.8, 32);
  // const bottomMaterial = new THREE.MeshToonMaterial({ color: '#ffffff' });
  // const bottom = new THREE.Mesh(bottomGeometry, bottomMaterial);
  // bottom.rotation.x = -Math.PI / 2;
  // bottom.position.y = -1.5;
  // cupGourp.add(bottom);

  // "Кофе"
  const coffeeGeometry = new THREE.CircleGeometry(getInnerRadius(), cupSizes.radialSegments);
  const coffeeMaterial = new THREE.MeshToonMaterial({ color: '#2b1a0a' }); // тёмно-коричневый
  const coffee = new THREE.Mesh(coffeeGeometry, coffeeMaterial);
  coffee.rotation.x = -Math.PI / 2;
  coffee.position.y = cupSizes.height / 2 - cupSizes.liquidOffsetFromTop;
  cupGourp.add(coffee);

  // Ручка (тор)
  const handleGeometry = new THREE.TorusGeometry(
    cupSizes.handle.ringRadius,
    cupSizes.handle.tubeRadius,
    16,
    100,
    cupSizes.handle.arc,
  );
  const handleMaterial = new THREE.MeshToonMaterial({ color: '#62adbf' });
  const handle = new THREE.Mesh(handleGeometry, handleMaterial);
  handle.rotation.z = -Math.PI / 2;
  handle.position.set(cupSizes.outerRadius, 0, 0);
  cupGourp.add(handle);

  scene.add(cupGourp);

  // === Функция обновления геометрий под текущие cupSizes ===
  const updateGeometries = () => {
    // Cup outer
    const newCupGeometry = new THREE.CylinderGeometry(
      cupSizes.outerRadius,
      cupSizes.outerRadius,
      cupSizes.height,
      Math.max(3, Math.floor(cupSizes.radialSegments)),
      1,
      true,
    );
    cup.geometry.dispose?.();
    cup.geometry = newCupGeometry;

    // Inner cylinder
    const newInnerGeometry = new THREE.CylinderGeometry(
      getInnerRadius(),
      getInnerRadius(),
      cupSizes.height,
      Math.max(3, Math.floor(cupSizes.radialSegments)),
      1,
      true,
    );
    inner.geometry.dispose?.();
    inner.geometry = newInnerGeometry;

    // Top ring border
    const newBorderGeometry = new THREE.RingGeometry(
      getInnerRadius(),
      cupSizes.outerRadius,
      Math.max(3, Math.floor(cupSizes.radialSegments)),
    );
    borderCup.geometry.dispose?.();
    borderCup.geometry = newBorderGeometry;
    borderCup.position.y = cupSizes.height / 2;

    // Coffee surface
    const newCoffeeGeometry = new THREE.CircleGeometry(
      getInnerRadius(),
      Math.max(3, Math.floor(cupSizes.radialSegments)),
    );
    coffee.geometry.dispose?.();
    coffee.geometry = newCoffeeGeometry;
    coffee.position.y = cupSizes.height / 2 - cupSizes.liquidOffsetFromTop;

    // Handle
    const newHandleGeometry = new THREE.TorusGeometry(
      cupSizes.handle.ringRadius,
      cupSizes.handle.tubeRadius,
      16,
      100,
      cupSizes.handle.arc,
    );
    handle.geometry.dispose?.();
    handle.geometry = newHandleGeometry;
    handle.position.set(cupSizes.outerRadius, 0, 0);
  };

  // === Tweakpane ===
  pane = new Pane({ title: 'Cup Sizes' });
  const gMain = pane.addFolder({ title: 'Main' });
  const gHandle = pane.addFolder({ title: 'Handle' });
  const gText = pane.addFolder({ title: 'Text' });

  // Binding to shift text texture horizontally around the cup
  const bTex = gMain.addBinding(cupSizes, 'textureOffsetX', { min: -1, max: 1, step: 0.01 });
  bTex.on('change', () => {
    textTexture.offset.x = cupSizes.textureOffsetX;
    textTexture.needsUpdate = true;
  });

  // Text bindings
  const gTitle = gText.addFolder({ title: 'Title' });
  const gSubtitle = gText.addFolder({ title: 'Subtitle' });

  const bTContent = gTitle.addBinding(cupSizes.text.title, 'content', {
    view: 'text',
    lineCount: 5,
  });
  bTContent.on('change', updateCanvasTexture);
  const bTFont = gTitle.addBinding(cupSizes.text.title, 'fontSize', { min: 8, max: 200, step: 1 });
  bTFont.on('change', updateCanvasTexture);
  const bTLH = gTitle.addBinding(cupSizes.text.title, 'lineHeight', { min: 8, max: 300, step: 1 });
  bTLH.on('change', updateCanvasTexture);
  const bTColor = gTitle.addBinding(cupSizes.text.title, 'color');
  bTColor.on('change', updateCanvasTexture);

  const bSContent = gSubtitle.addBinding(cupSizes.text.subtitle, 'content', {
    view: 'text',
    lineCount: 3,
  });
  bSContent.on('change', updateCanvasTexture);
  const bSFont = gSubtitle.addBinding(cupSizes.text.subtitle, 'fontSize', {
    min: 8,
    max: 200,
    step: 1,
  });
  bSFont.on('change', updateCanvasTexture);
  const bSLH = gSubtitle.addBinding(cupSizes.text.subtitle, 'lineHeight', {
    min: 8,
    max: 300,
    step: 1,
  });
  bSLH.on('change', updateCanvasTexture);
  const bSColor = gSubtitle.addBinding(cupSizes.text.subtitle, 'color');
  bSColor.on('change', updateCanvasTexture);

  const bBg = gText.addBinding(cupSizes.text, 'background');
  bBg.on('change', updateCanvasTexture);
  const bPad = gText.addBinding(cupSizes.text, 'padding', { min: 0, max: 200, step: 1 });
  bPad.on('change', updateCanvasTexture);
  const bPpu = gText.addBinding(cupSizes.text, 'pxPerUnit', { min: 16, max: 512, step: 1 });
  bPpu.on('change', updateCanvasTexture);

  const bindings = [
    gMain.addBinding(cupSizes, 'height', { min: 1, max: 12, step: 0.1 }),
    gMain.addBinding(cupSizes, 'outerRadius', { min: 0.5, max: 4, step: 0.05 }),
    gMain.addBinding(cupSizes, 'wallThickness', { min: 0.05, max: 1, step: 0.01 }),
    gMain.addBinding(cupSizes, 'radialSegments', { min: 8, max: 128, step: 1 }),
    gMain.addBinding(cupSizes, 'liquidOffsetFromTop', { min: 0, max: 2, step: 0.01 }),
    gHandle.addBinding(cupSizes.handle, 'ringRadius', { min: 0.2, max: 2.5, step: 0.01 }),
    gHandle.addBinding(cupSizes.handle, 'tubeRadius', { min: 0.05, max: 1, step: 0.01 }),
    gHandle.addBinding(cupSizes.handle, 'arc', { min: Math.PI / 4, max: Math.PI * 2, step: 0.01 }),
  ];
  bindings.forEach((b) =>
    b.on('change', () => {
      updateGeometries();
      updateCanvasTexture();
    }),
  );

  // === Кнопка копирования настроек в буфер обмена ===
  const copyBtn = pane.addButton({ title: 'Скопировать настройки' });
  copyBtn.on('click', async () => {
    try {
      // Снимок текущих настроек без реактивности
      const snapshot = JSON.parse(
        JSON.stringify({
          height: cupSizes.height,
          outerRadius: cupSizes.outerRadius,
          wallThickness: cupSizes.wallThickness,
          radialSegments: cupSizes.radialSegments,
          textureOffsetX: cupSizes.textureOffsetX,
          liquidOffsetFromTop: cupSizes.liquidOffsetFromTop,
          text: {
            title: {
              content: cupSizes.text.title.content,
              fontSize: cupSizes.text.title.fontSize,
              lineHeight: cupSizes.text.title.lineHeight,
              color: cupSizes.text.title.color,
            },
            subtitle: {
              content: cupSizes.text.subtitle.content,
              fontSize: cupSizes.text.subtitle.fontSize,
              lineHeight: cupSizes.text.subtitle.lineHeight,
              color: cupSizes.text.subtitle.color,
            },
            background: cupSizes.text.background,
            padding: cupSizes.text.padding,
            pxPerUnit: cupSizes.text.pxPerUnit,
          },
          handle: {
            ringRadius: cupSizes.handle.ringRadius,
            tubeRadius: cupSizes.handle.tubeRadius,
            arc: cupSizes.handle.arc,
          },
        }),
      );

      const text = JSON.stringify(snapshot, null, 2);
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(text);
      } else {
        const ta = document.createElement('textarea');
        ta.value = text;
        document.body.appendChild(ta);
        ta.select();
        document.execCommand('copy');
        document.body.removeChild(ta);
      }
      // Простое подтверждение
      console.log('Cup settings copied to clipboard');
      alert('Настройки скопированы в буфер обмена. Вставьте их в cupSizes.');
    } catch (e) {
      console.error('Failed to copy cup settings', e);
      alert('Не удалось скопировать настройки');
    }
  });

  // === Рендер цикл ===
  function animate() {
    requestAnimationFrame(animate);
    controls.update();
    renderer.render(scene, camera);
  }

  animate();

  window.addEventListener('resize', onResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', onResize);
  if (pane) {
    pane.dispose();
    pane = null;
  }
  // Dispose renderer to free WebGL context
  if (renderer) {
    renderer.dispose?.();
  }
});
</script>

<style scoped>
canvas {
  width: 100%;
  height: 100%;
  display: block;
}
</style>
