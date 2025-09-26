<template>
  <canvas ref="canvas"></canvas>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref, reactive } from 'vue';
import * as THREE from 'three';
import { Pane } from 'tweakpane';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { isMobile } from './utils.ts';

gsap.registerPlugin(ScrollTrigger);

interface CupProps {
  title: string;
  titleColor?: string;
  subtitle?: string;
  subtitleColor?: string;
  backText?: string;
  backTextColor?: string;
}

const props = withDefaults(defineProps<{ cups: CupProps[] }>(), {
  cups: () => [
    {
      title: 'Спасибо за такое атмосферное мероприятие!',
      subtitle: 'Отличная организация, тематические локации и перформанс!',
      backText: '',
      backTextColor: '#0e586b',
    },
  ],
});

const canvas = ref<HTMLCanvasElement | null>(null);

let camera: any;
let renderer: any;
let controls: any;
let pane: Pane | null = null;
let dirLight: THREE.DirectionalLight | null = null;

const sceneSettings = reactive({
  camera: {
    fov: 35,
    position: { x: 0, y: 6.5, z: 11 },
    target: { x: 0, y: 2, z: 0 },
  },
  light: {
    color: '#ffffff',
    intensity: 3,
    position: { x: 0, y: 4, z: 0 },
  },
});

const cupSizes = reactive({
  // common geometrical parameters
  height: 4.5,
  outerRadius: 2,
  wallThickness: 0.2,
  radialSegments: 64,
  // distance between cups along X
  spacingX: 7,
  // horizontal offset of the text texture around the cup (UV.x)
  textureOffsetX: 0.52,
  // how far the liquid surface is below the top edge
  liquidOffsetFromTop: 0.55,
  // text parameters
  text: {
    title: {
      content: 'Спасибо за такое атмосферное мероприятие!',
      fontSize: 54,
      lineHeight: 60,
      color: '#0e586b',
    },
    subtitle: {
      content: 'Отличная организация, тематические локации и перформанс!',
      fontSize: 36,
      lineHeight: 44,
      color: '#0e586b',
    },
    background: '#f2e7db',
    padding: 140,
    pxPerUnit: 128, // pixels per world unit (affects canvas resolution)
  },
  // back text parameters (rendered on the opposite side, no subtitle)
  backtext: {
    title: {
      content: '',
      fontSize: 54,
      lineHeight: 60,
      color: '#0e586b',
    },
    padding: 140,
  },
  // handle parameters
  handle: {
    ringRadius: 1.2,
    tubeRadius: 0.25,
    arc: Math.PI,
  },
});

// Initialize text content/colors from the first cup in props (if provided)
if (Array.isArray(props.cups) && props.cups.length > 0) {
  const first = props.cups[0];
  if (first.title) cupSizes.text.title.content = first.title;
  if (first.titleColor) cupSizes.text.title.color = first.titleColor;
  if (first.subtitle !== undefined) cupSizes.text.subtitle.content = first.subtitle || '';
  if (first.subtitleColor) cupSizes.text.subtitle.color = first.subtitleColor;
  // Initialize back text from props as well
  if (first.backText !== undefined) cupSizes.backtext.title.content = first.backText || '';
  if ((first as any).backTextColor)
    cupSizes.backtext.title.color = (first as any).backTextColor as string;
}

const getInnerRadius = () => cupSizes.outerRadius - cupSizes.wallThickness;

const onResize = () => {
  if (!canvas.value?.parentElement || !renderer || !camera) {
    return;
  }
  const { width, height } = canvas.value.parentElement.getBoundingClientRect();
  // const width = window.innerWidth;
  // const height = window.innerHeight;

  // Update camera
  camera.aspect = width / height || 1;
  camera.updateProjectionMatrix();

  renderer.setSize(width, height, false);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
};

onMounted(() => {
  if (!canvas.value?.parentElement) {
    return;
  }
  // canvas
  const { width, height } = canvas.value.parentElement.getBoundingClientRect();

  const scene = new THREE.Scene();
  const axesHelper = new THREE.AxesHelper(5);
  // scene.add(axesHelper);
  scene.background = null;

  camera = new THREE.PerspectiveCamera(sceneSettings.camera.fov, width / height, 0.1, 100);
  // camera = new THREE.OrthographicCamera(
  //   width / -80,
  //   width / 80,
  //   height / 80,
  //   height / -80,
  //   1,
  //   1000,
  // );
  camera.position.set(
    sceneSettings.camera.position.x,
    sceneSettings.camera.position.y,
    sceneSettings.camera.position.z,
  );

  renderer = new THREE.WebGLRenderer({ canvas: canvas.value, antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setSize(width, height, false);
  // Make the canvas fully transparent so underlying CSS background is visible
  renderer.setClearColor(0x000000, 0);

  // Contorls
  // controls = new OrbitControls(camera, renderer.domElement);
  // controls.enableDamping = true;
  // // Prevent the camera from going below the horizon relative to the target
  // controls.maxPolarAngle = Math.PI / 2; // look no further down than the horizon
  // // Keep panning parallel to the ground plane so Y doesn't change while panning
  // controls.screenSpacePanning = false;
  // // Apply initial target for where the camera looks
  // controls.target.set(
  //   sceneSettings.camera.target.x,
  //   sceneSettings.camera.target.y,
  //   sceneSettings.camera.target.z,
  // );
  // controls.update();

  // Свет для toon-материала
  dirLight = new THREE.DirectionalLight(
    sceneSettings.light.color as any,
    sceneSettings.light.intensity,
  );
  dirLight.position.set(
    sceneSettings.light.position.x,
    sceneSettings.light.position.y,
    sceneSettings.light.position.z,
  );
  scene.add(dirLight);

  // Стол
  const table = new THREE.Mesh(
    new THREE.PlaneGeometry(80, 12),
    new THREE.MeshBasicMaterial({ color: '#5fbaaa' }),
  );
  table.position.set(0, 0, 0);
  // const angleDegrees = -90;
  // const angleRadians = THREE.MathUtils.degToRad(angleDegrees);
  // Поворот вокруг оси X
  table.rotation.x = -Math.PI / 2;
  scene.add(table);

  // === КРУЖКА ===
  const cupGourp = new THREE.Group();

  // === создаём canvas и функции отрисовки текста ===
  const canvasText = document.createElement('canvas');
  const ctx = canvasText.getContext('2d')!;

  // Хранилище всех текстур для обновления смещения
  const allTextTextures: THREE.CanvasTexture[] = [];

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
    const sizeChanged = canvasText.width !== width || canvasText.height !== height;
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

    // Back text (title only), centered on the opposite side (UV shift by 0.5)
    const backTitleFontSize = Math.max(6, Math.floor(cupSizes.backtext.title.fontSize));
    const backTitleLineHeight = Math.max(
      backTitleFontSize + 2,
      Math.floor(cupSizes.backtext.title.lineHeight),
    );
    const backTitleFont = `700 ${backTitleFontSize}px 'Inter Tight'`;

    const backTitleLines = wrapLines(
      cupSizes.backtext.title.content || '',
      contentWidth,
      backTitleFont,
      backTitleLineHeight,
    );
    const backTotalHeight = backTitleLines.length * backTitleLineHeight;
    let yBack = Math.floor((height - backTotalHeight) / 2);

    ctx.font = backTitleFont;
    ctx.fillStyle = cupSizes.backtext.title.color;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    // draw twice for wrap-around: at x=0 and x=width
    for (const line of backTitleLines) {
      ctx.fillText(line, 0, yBack);
      ctx.fillText(line, width, yBack);
      yBack += backTitleLineHeight;
    }

    textTexture.needsUpdate = true;
    if (sizeChanged) {
      recreateTextTexture();
    }
  };

  // Создать отдельную текстуру для указанного содержимого (для других кружек)
  function createCanvasTextureWithContent(opts: {
    title?: string;
    subtitle?: string;
    titleColor?: string;
    subtitleColor?: string;
    backText?: string;
    backTextColor?: string;
  }): THREE.CanvasTexture {
    const { width, height } = computeCanvasSize();
    const canvas2 = document.createElement('canvas');
    const ctx2 = canvas2.getContext('2d')!;

    canvas2.width = width;
    canvas2.height = height;

    // Background
    ctx2.fillStyle = cupSizes.text.background;
    ctx2.fillRect(0, 0, width, height);

    // Layout
    const areaWidth = Math.max(10, Math.floor(width * 0.5));
    const pad = Math.max(0, Math.floor(cupSizes.text.padding));
    const contentWidth = Math.max(10, areaWidth - pad * 2);
    const areaX = Math.floor((width - areaWidth) / 2) + pad;

    // Fonts
    const titleFontSize = Math.max(6, Math.floor(cupSizes.text.title.fontSize));
    const titleLineHeight = Math.max(titleFontSize + 2, Math.floor(cupSizes.text.title.lineHeight));
    const titleFont = `700 ${titleFontSize}px 'Inter Tight'`;

    const subtitleFontSize = Math.max(6, Math.floor(cupSizes.text.subtitle.fontSize));
    const subtitleLineHeight = Math.max(
      subtitleFontSize + 2,
      Math.floor(cupSizes.text.subtitle.lineHeight),
    );
    const subtitleFont = `600 ${subtitleFontSize}px 'Inter Tight'`;

    const titleText = opts.title ?? '';
    const subtitleText = opts.subtitle ?? '';

    const titleLines = (function () {
      ctx2.font = titleFont;
      return wrapLines(titleText, contentWidth, titleFont, titleLineHeight);
    })();
    const subtitleLines = (function () {
      ctx2.font = subtitleFont;
      return wrapLines(subtitleText, contentWidth, subtitleFont, subtitleLineHeight);
    })();

    const totalTextHeight =
      titleLines.length * titleLineHeight + subtitleLines.length * subtitleLineHeight;
    let y = Math.floor((height - totalTextHeight) / 2);

    ctx2.textAlign = 'center';
    ctx2.textBaseline = 'top';

    // Draw title
    ctx2.font = titleFont;
    ctx2.fillStyle = opts.titleColor || cupSizes.text.title.color;
    for (const line of titleLines) {
      ctx2.fillText(line, areaX + contentWidth / 2, y);
      y += titleLineHeight;
    }

    // Draw subtitle
    ctx2.font = subtitleFont;
    ctx2.fillStyle = opts.subtitleColor || cupSizes.text.subtitle.color;
    for (const line of subtitleLines) {
      ctx2.fillText(line, areaX + contentWidth / 2, y);
      y += subtitleLineHeight;
    }

    // Back text (title only) on the opposite side
    const backTitleFontSize = Math.max(6, Math.floor(cupSizes.backtext.title.fontSize));
    const backTitleLineHeight = Math.max(
      backTitleFontSize + 2,
      Math.floor(cupSizes.backtext.title.lineHeight),
    );
    const backTitleFont = `700 ${backTitleFontSize}px 'Inter Tight'`;

    const backTitleLines = (function () {
      ctx2.font = backTitleFont;
      return wrapLines(
        (opts.backText ?? cupSizes.backtext.title.content) || '',
        contentWidth,
        backTitleFont,
        backTitleLineHeight,
      );
    })();

    const backTotalHeight = backTitleLines.length * backTitleLineHeight;
    let yBack = Math.floor((canvas2.height - backTotalHeight) / 2);

    ctx2.font = backTitleFont;
    ctx2.fillStyle = opts.backTextColor || cupSizes.backtext.title.color;
    ctx2.textAlign = 'center';
    ctx2.textBaseline = 'top';
    for (const line of backTitleLines) {
      ctx2.fillText(line, 0, yBack);
      ctx2.fillText(line, canvas2.width, yBack);
      yBack += backTitleLineHeight;
    }

    const tex = new THREE.CanvasTexture(canvas2);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.offset.x = cupSizes.textureOffsetX;
    tex.needsUpdate = true;
    tex.generateMipmaps = false;
    tex.minFilter = THREE.LinearFilter;
    tex.magFilter = THREE.LinearFilter;
    return tex;
  }

  // === текстура ===
  let textTexture: THREE.CanvasTexture = new THREE.CanvasTexture(canvasText);
  textTexture.needsUpdate = true;
  textTexture.wrapS = THREE.RepeatWrapping;
  textTexture.wrapT = THREE.RepeatWrapping;
  textTexture.generateMipmaps = false;
  textTexture.minFilter = THREE.LinearFilter;
  textTexture.magFilter = THREE.LinearFilter;
  // Смещение текста по окружности
  textTexture.offset.x = cupSizes.textureOffsetX;
  allTextTextures.push(textTexture);

  // Предварительное объявление материала кружки, чтобы избежать TDZ в recreateTextTexture
  let cupMaterial: THREE.MeshToonMaterial | null = null;

  // При смене размеров канваса пересоздаём текстуру и переназначаем материал
  function recreateTextTexture() {
    const old = textTexture;
    const newTex = new THREE.CanvasTexture(canvasText);
    newTex.wrapS = THREE.RepeatWrapping;
    newTex.wrapT = THREE.RepeatWrapping;
    newTex.offset.x = cupSizes.textureOffsetX;
    newTex.needsUpdate = true;
    newTex.generateMipmaps = false;
    newTex.minFilter = THREE.LinearFilter;
    newTex.magFilter = THREE.LinearFilter;
    textTexture = newTex;
    if (cupMaterial) {
      cupMaterial.map = newTex;
      cupMaterial.needsUpdate = true;
    }
    // обновим ссылку первой текстуры
    if (allTextTextures.length > 0) {
      allTextTextures[0] = newTex;
    } else {
      allTextTextures.push(newTex);
    }
    old.dispose?.();
  }

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
  cupMaterial = new THREE.MeshToonMaterial({
    map: textTexture,
    // emissive: '#0e586b',
  });
  const cup = new THREE.Mesh(cupGeometry, cupMaterial!);
  cup.name = 'cup';
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
  inner.name = 'inner';
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
  borderCup.name = 'border';
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
  coffee.name = 'coffee';
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
  handle.name = 'handle';
  handle.rotation.z = -Math.PI / 2;
  handle.position.set(cupSizes.outerRadius, 0, 0);
  cupGourp.add(handle);
  cupGourp.position.set(0, cupSizes.height / 2, 0);
  scene.add(cupGourp);

  // Additional cups to the right based on props.cups length
  const cupGroups: THREE.Group[] = [cupGourp];
  if (Array.isArray(props.cups) && props.cups.length > 1) {
    for (let i = 1; i < props.cups.length; i++) {
      const clone = cupGourp.clone(true);
      clone.position.set(i * cupSizes.spacingX, cupSizes.height / 2, 0);
      scene.add(clone);
      cupGroups.push(clone);
    }
  }

  // Для клонов назначаем индивидуальные текстуры с их контентом
  if (Array.isArray(props.cups)) {
    for (let i = 1; i < Math.min(props.cups.length, cupGroups.length); i++) {
      const g = cupGroups[i];
      const cupMesh = g.getObjectByName('cup') as THREE.Mesh | null;
      if (cupMesh) {
        const cupData = props.cups[i] || ({} as any);
        const tex = createCanvasTextureWithContent({
          title: cupData.title,
          subtitle: cupData.subtitle,
          titleColor: cupData.titleColor,
          subtitleColor: cupData.subtitleColor,
          backText: cupData.backText,
          backTextColor: cupData.backTextColor,
        });
        allTextTextures.push(tex);
        const mat = new THREE.MeshToonMaterial({ map: tex });
        cupMesh.material = mat;
      }
    }
  }

  const repositionGroups = () => {
    for (let i = 0; i < cupGroups.length; i++) {
      cupGroups[i].position.set(i * cupSizes.spacingX, cupSizes.height / 2, 0);
    }
  };

  const syncGeometriesToClones = () => {
    const src = cupGourp;
    const srcCup = src.getObjectByName('cup') as THREE.Mesh | null;
    const srcInner = src.getObjectByName('inner') as THREE.Mesh | null;
    const srcBorder = src.getObjectByName('border') as THREE.Mesh | null;
    const srcCoffee = src.getObjectByName('coffee') as THREE.Mesh | null;
    const srcHandle = src.getObjectByName('handle') as THREE.Mesh | null;
    for (let i = 1; i < cupGroups.length; i++) {
      const g = cupGroups[i];
      const dstCup = g.getObjectByName('cup') as THREE.Mesh | null;
      const dstInner = g.getObjectByName('inner') as THREE.Mesh | null;
      const dstBorder = g.getObjectByName('border') as THREE.Mesh | null;
      const dstCoffee = g.getObjectByName('coffee') as THREE.Mesh | null;
      const dstHandle = g.getObjectByName('handle') as THREE.Mesh | null;
      if (dstCup && srcCup) dstCup.geometry = srcCup.geometry;
      if (dstInner && srcInner) dstInner.geometry = srcInner.geometry;
      if (dstBorder && srcBorder) dstBorder.geometry = srcBorder.geometry;
      if (dstCoffee && srcCoffee) dstCoffee.geometry = srcCoffee.geometry;
      if (dstHandle && srcHandle) dstHandle.geometry = srcHandle.geometry;
    }
  };

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
    // Sync clone geometries and reposition all groups
    syncGeometriesToClones();
    repositionGroups();
  };

  // === Управление: горизонтальная карусель со снапом + вращение выбранной кружки ===
  let activeIndex = 0;
  const maxIndex = Math.max(0, (Array.isArray(props.cups) ? props.cups.length : 1) - 1);
  let currX = 0; // camera/target X
  let isDown = false;
  let mode: 'idle' | 'carousel' | 'rotate' = 'idle';
  let selectedGroup: THREE.Group | null = null;
  let startClientX = 0;
  let dragStartX = 0;
  let startRotY = 0;
  let snapTween: gsap.core.Tween | null = null;
  // Track if we temporarily disabled GSAP's ScrollTrigger.normalizeScroll during interaction
  let normalizerTemporarilyDisabled = false;

  function setCameraX(x: number) {
    currX = Math.max(0, Math.min(x, centerXForIndex(maxIndex)));
    camera.position.x = currX;
    sceneSettings.camera.position.x = currX;
    sceneSettings.camera.target.x = currX;
    // keep looking at Y/Z target position
    camera.lookAt(
      new THREE.Vector3(
        sceneSettings.camera.target.x,
        sceneSettings.camera.target.y,
        sceneSettings.camera.target.z,
      ),
    );
  }

  function clampIndex(i: number) {
    return Math.max(0, Math.min(i, maxIndex));
  }
  function centerXForIndex(i: number) {
    return clampIndex(i) * cupSizes.spacingX;
  }
  function nearestIndexByX(xVal: number) {
    return clampIndex(Math.round(xVal / Math.max(0.0001, cupSizes.spacingX)));
  }
  function updateActiveByX(xVal: number) {
    const idx = nearestIndexByX(xVal);
    if (idx !== activeIndex) activeIndex = idx;
  }
  function stopSnap() {
    if (snapTween) {
      snapTween.kill();
      snapTween = null;
    }
  }
  function snapToNearest(duration = 0.35) {
    const targetIdx = nearestIndexByX(currX);
    const toX = centerXForIndex(targetIdx);
    stopSnap();
    const proxy = { v: currX };
    snapTween = gsap.to(proxy, {
      v: toX,
      duration,
      ease: 'power3.out',
      onUpdate: () => {
        setCameraX(proxy.v);
        updateActiveByX(proxy.v);
      },
      onComplete: () => {
        activeIndex = targetIdx;
        snapTween = null;
      },
    });
  }
  function goToIndex(idx: number, duration = 0.45) {
    idx = clampIndex(idx);
    const toX = centerXForIndex(idx);
    stopSnap();
    const proxy = { v: currX };
    snapTween = gsap.to(proxy, {
      v: toX,
      duration,
      ease: 'power3.out',
      onUpdate: () => setCameraX(proxy.v),
      onComplete: () => {
        activeIndex = idx;
        snapTween = null;
      },
    });
  }

  const raycaster = new THREE.Raycaster();
  const ndc = new THREE.Vector2();
  const cupMeshSet = new Set<THREE.Object3D>();
  // collect cup meshes (outer shell) for hit test
  for (const g of cupGroups) {
    const m = g.getObjectByName('cup');
    if (m) cupMeshSet.add(m);
  }
  function setNdcFromEvent(ev: PointerEvent) {
    const rect = renderer.domElement.getBoundingClientRect();
    ndc.x = ((ev.clientX - rect.left) / rect.width) * 2 - 1;
    ndc.y = -(((ev.clientY - rect.top) / rect.height) * 2 - 1);
  }
  function pickGroup(ev: PointerEvent): THREE.Group | null {
    setNdcFromEvent(ev);
    raycaster.setFromCamera(ndc, camera);
    const intersects = raycaster.intersectObjects(Array.from(cupMeshSet), true);
    if (!intersects.length) return null;
    let obj: THREE.Object3D | null = intersects[0].object;
    while (obj && !(obj instanceof THREE.Group)) {
      obj = obj.parent;
    }
    // ensure it's one of known groups
    if (obj && cupGroups.includes(obj as THREE.Group)) return obj as THREE.Group;
    return intersects[0].object.parent as THREE.Group | null;
  }

  function onPointerDown(ev: PointerEvent) {
    ev.preventDefault();
    ev.stopPropagation();

    // On mobile, temporarily disable GSAP's normalizeScroll so our touch-action and preventDefault can stop page scrolling
    if (isMobile() && !normalizerTemporarilyDisabled) {
      try {
        ScrollTrigger.normalizeScroll(false);
        normalizerTemporarilyDisabled = true;
      } catch (err) {
        // ignore
      }
    }

    isDown = true;
    startClientX = ev.clientX;
    dragStartX = currX;
    stopSnap();
    const g = pickGroup(ev);
    if (g) {
      mode = 'rotate';
      selectedGroup = g;
      startRotY = g.rotation.y;
    } else {
      mode = 'carousel';
      selectedGroup = null;
    }
    (ev.target as Element).setPointerCapture?.(ev.pointerId);
  }
  function onPointerMove(ev: PointerEvent) {
    if (!isDown) return;
    const dx = ev.clientX - startClientX;
    if (mode === 'carousel') {
      const sensitivity = Math.max(0.002, cupSizes.spacingX / 300); // world units per pixel
      const nextX = dragStartX - dx * sensitivity;
      setCameraX(nextX);
      updateActiveByX(nextX);
    } else if (mode === 'rotate' && selectedGroup) {
      const rotSensitivity = 0.01; // radians per pixel
      selectedGroup.rotation.y = startRotY - dx * rotSensitivity;
    }
  }
  function onPointerUp() {
    if (!isDown) return;
    isDown = false;
    if (mode === 'carousel') {
      snapToNearest();
    }
    mode = 'idle';
    selectedGroup = null;

    // Re-enable normalizeScroll after interaction
    if (normalizerTemporarilyDisabled) {
      try {
        ScrollTrigger.normalizeScroll(true);
      } catch (err) {
        // ignore
      }
      normalizerTemporarilyDisabled = false;
    }
  }
  function onPointerCancel() {
    if (!isDown) return;
    isDown = false;
    if (mode === 'carousel') {
      snapToNearest();
    }
    mode = 'idle';
    selectedGroup = null;
    if (normalizerTemporarilyDisabled) {
      try {
        ScrollTrigger.normalizeScroll(true);
      } catch (err) {
        // ignore
      }
      normalizerTemporarilyDisabled = false;
    }
  }
  function onWheel(e: WheelEvent) {
    // Disable zoom/scroll; use wheel to step horizontally
    // e.preventDefault();
    // e.stopPropagation();
    // const delta = e.deltaY || e.deltaX || 0;
    // if (Math.abs(delta) < 2) return;
    // const step = delta > 0 ? 1 : -1;
    // goToIndex(activeIndex + step);
  }

  // init camera at first cup
  setCameraX(centerXForIndex(0));

  // listeners on canvas
  renderer.domElement.addEventListener('pointerdown', onPointerDown);
  window.addEventListener('pointermove', onPointerMove);
  window.addEventListener('pointerup', onPointerUp);
  window.addEventListener('pointercancel', onPointerCancel);
  renderer.domElement.addEventListener('wheel', onWheel, { passive: false });

  // === Tweakpane ===
  pane = new Pane({ title: 'Cup Settings', expanded: false });
  const gMain = pane.addFolder({ title: 'Main', expanded: false });
  const gHandle = pane.addFolder({ title: 'Handle', expanded: false });
  const gText = pane.addFolder({ title: 'Text', expanded: false });
  const gCamera = pane.addFolder({ title: 'Camera', expanded: false });
  const gLight = pane.addFolder({ title: 'Light', expanded: false });

  // Camera bindings
  const bFov = gCamera.addBinding(sceneSettings.camera, 'fov', { min: 10, max: 120, step: 1 });
  bFov.on('change', () => {
    if (!camera) return;
    camera.fov = sceneSettings.camera.fov;
    camera.updateProjectionMatrix();
  });
  const bCamX = gCamera.addBinding(sceneSettings.camera.position, 'x', {
    min: -20,
    max: 20,
    step: 0.1,
  });
  bCamX.on('change', () => {
    camera?.position.set(
      sceneSettings.camera.position.x,
      sceneSettings.camera.position.y,
      sceneSettings.camera.position.z,
    );
  });
  const bCamY = gCamera.addBinding(sceneSettings.camera.position, 'y', {
    min: -20,
    max: 20,
    step: 0.1,
  });
  bCamY.on('change', () => {
    camera?.position.set(
      sceneSettings.camera.position.x,
      sceneSettings.camera.position.y,
      sceneSettings.camera.position.z,
    );
  });
  const bCamZ = gCamera.addBinding(sceneSettings.camera.position, 'z', {
    min: -20,
    max: 20,
    step: 0.1,
  });
  bCamZ.on('change', () => {
    camera?.position.set(
      sceneSettings.camera.position.x,
      sceneSettings.camera.position.y,
      sceneSettings.camera.position.z,
    );
  });
  // Camera target (look at) bindings
  // const bTarX = gCamera.addBinding(sceneSettings.camera.target, 'x', {
  //   min: -20,
  //   max: 20,
  //   step: 0.1,
  // });
  // bTarX.on('change', () => {
  //   controls?.target.set(
  //     sceneSettings.camera.target.x,
  //     sceneSettings.camera.target.y,
  //     sceneSettings.camera.target.z,
  //   );
  //   controls?.update();
  // });
  // const bTarY = gCamera.addBinding(sceneSettings.camera.target, 'y', {
  //   min: -20,
  //   max: 20,
  //   step: 0.1,
  // });
  // bTarY.on('change', () => {
  //   controls?.target.set(
  //     sceneSettings.camera.target.x,
  //     sceneSettings.camera.target.y,
  //     sceneSettings.camera.target.z,
  //   );
  //   controls?.update();
  // });
  // const bTarZ = gCamera.addBinding(sceneSettings.camera.target, 'z', {
  //   min: -20,
  //   max: 20,
  //   step: 0.1,
  // });
  // bTarZ.on('change', () => {
  //   controls?.target.set(
  //     sceneSettings.camera.target.x,
  //     sceneSettings.camera.target.y,
  //     sceneSettings.camera.target.z,
  //   );
  //   controls?.update();
  // });

  // Light bindings
  const bLightColor = gLight.addBinding(sceneSettings.light, 'color');
  bLightColor.on('change', () => {
    if (dirLight) dirLight.color = new THREE.Color(sceneSettings.light.color as any);
  });
  const bLightIntensity = gLight.addBinding(sceneSettings.light, 'intensity', {
    min: 0,
    max: 10,
    step: 0.01,
  });
  bLightIntensity.on('change', () => {
    if (dirLight) dirLight.intensity = sceneSettings.light.intensity;
  });
  const bLightX = gLight.addBinding(sceneSettings.light.position, 'x', {
    min: -20,
    max: 20,
    step: 0.1,
  });
  bLightX.on('change', () => {
    dirLight?.position.set(
      sceneSettings.light.position.x,
      sceneSettings.light.position.y,
      sceneSettings.light.position.z,
    );
  });
  const bLightY = gLight.addBinding(sceneSettings.light.position, 'y', {
    min: -20,
    max: 20,
    step: 0.1,
  });
  bLightY.on('change', () => {
    dirLight?.position.set(
      sceneSettings.light.position.x,
      sceneSettings.light.position.y,
      sceneSettings.light.position.z,
    );
  });
  const bLightZ = gLight.addBinding(sceneSettings.light.position, 'z', {
    min: -20,
    max: 20,
    step: 0.1,
  });
  bLightZ.on('change', () => {
    dirLight?.position.set(
      sceneSettings.light.position.x,
      sceneSettings.light.position.y,
      sceneSettings.light.position.z,
    );
  });

  // Binding to shift text texture horizontally around the cup
  const bTex = gMain.addBinding(cupSizes, 'textureOffsetX', { min: -1, max: 1, step: 0.01 });
  bTex.on('change', () => {
    for (const tex of allTextTextures) {
      tex.offset.x = cupSizes.textureOffsetX;
      tex.needsUpdate = true;
    }
  });

  // Text bindings
  const gTitle = gText.addFolder({ title: 'Title' });
  const gSubtitle = gText.addFolder({ title: 'Subtitle' });
  const gBackText = gText.addFolder({ title: 'Back Text' });

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

  // Back Text bindings (title only)
  const bBTContent = gBackText.addBinding(cupSizes.backtext.title, 'content', {
    view: 'text',
    lineCount: 5,
  });
  bBTContent.on('change', updateCanvasTexture);
  const bBTFont = gBackText.addBinding(cupSizes.backtext.title, 'fontSize', {
    min: 8,
    max: 200,
    step: 1,
  });
  bBTFont.on('change', updateCanvasTexture);
  const bBTLH = gBackText.addBinding(cupSizes.backtext.title, 'lineHeight', {
    min: 8,
    max: 300,
    step: 1,
  });
  bBTLH.on('change', updateCanvasTexture);
  const bBTColor = gBackText.addBinding(cupSizes.backtext.title, 'color');
  bBTColor.on('change', updateCanvasTexture);

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
  const bSpacing = gMain.addBinding(cupSizes, 'spacingX', { min: 0.1, max: 20, step: 0.1 });
  bSpacing.on('change', () => {
    repositionGroups();
    // recenter camera to current active index when spacing changes
    setCameraX(centerXForIndex(activeIndex));
  });
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
          spacingX: cupSizes.spacingX,
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
          backtext: {
            title: {
              content: cupSizes.backtext.title.content,
              fontSize: cupSizes.backtext.title.fontSize,
              lineHeight: cupSizes.backtext.title.lineHeight,
              color: cupSizes.backtext.title.color,
            },
            padding: cupSizes.backtext.padding,
          },
          handle: {
            ringRadius: cupSizes.handle.ringRadius,
            tubeRadius: cupSizes.handle.tubeRadius,
            arc: cupSizes.handle.arc,
          },
          camera: {
            fov: sceneSettings.camera.fov,
            position: {
              x: sceneSettings.camera.position.x,
              y: sceneSettings.camera.position.y,
              z: sceneSettings.camera.position.z,
            },
            target: {
              x: sceneSettings.camera.target.x,
              y: sceneSettings.camera.target.y,
              z: sceneSettings.camera.target.z,
            },
          },
          light: {
            color: sceneSettings.light.color,
            intensity: sceneSettings.light.intensity,
            position: {
              x: sceneSettings.light.position.x,
              y: sceneSettings.light.position.y,
              z: sceneSettings.light.position.z,
            },
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
    controls?.update();
    renderer.render(scene, camera);
  }

  animate();

  window.addEventListener('resize', onResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', onResize);
  // remove interaction listeners
  if (renderer?.domElement) {
    renderer.domElement.removeEventListener('pointerdown', onPointerDown as any);
    renderer.domElement.removeEventListener('wheel', onWheel as any);
  }
  window.removeEventListener('pointermove', onPointerMove as any);
  window.removeEventListener('pointerup', onPointerUp as any);
  window.removeEventListener('pointercancel', onPointerCancel as any);
  if (pane) {
    pane.dispose();
    pane = null;
  }
  // stop any running tween
  try {
    (snapTween as any)?.kill?.();
  } catch {}

  // Safety: ensure normalizer gets re-enabled if component unmounts during interaction
  if (normalizerTemporarilyDisabled) {
    try {
      ScrollTrigger.normalizeScroll(true);
    } catch (err) {
      // ignore
    }
    normalizerTemporarilyDisabled = false;
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
  background: transparent; /* allow CSS page background to show through */
  -webkit-touch-callout: none;
  -webkit-user-select: none;
  user-select: none;
  touch-action: none;
}
</style>
