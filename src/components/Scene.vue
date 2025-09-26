<template>
  <div>
    <!-- Секция со сценой -->
    <section ref="sceneSection" class="scene-section">
      <canvas ref="canvas"></canvas>
    </section>

    <!-- Обычный контент после анимации -->
    <section class="content">
      <div class="cards-section z-0 relative overflow-hidden">
        <div class="cards relative z-10 px-12 pt-12">
          <span class="text-cyan-900">
            УПРАВЛЕНИЕ  ИТ-ПРОЕКТАМИ ЭТО КАК ПРОХОДИТЬ ЧЕРЕЗ РАЗДЕЛЕНИЕ Сайт рыбатекст поможет
            дизайнеру, верстальщику, вебмастеру сгенерировать несколько абзацев более менее
            осмысленного текста рыбы на русском языке, а начинающему оратору отточить навык
            публичных выступлений в домашних условиях.  При создании генератора мы использовали
            небезизвестный универсальный код речей. Текст генерируется абзацами случайным образом
            от двух до десяти предложений в абзаце.
          </span>
        </div>
        <div class="cards__spacer relative" ref="badgeTriggerAnimationRef">
          <!-- бейдж -->
          <div class="badge-wrapper z-0 overflow-hidden">
            <div class="string" :style="{ height: stringHeight + 'px' }"></div>
            <div
              ref="badgeRef"
              class="badge w-full z-10"
              :style="{ transform: `translateY(${badgeOffset}px)` }"
            >
              <HorizontalCarousel
                class="relative z-10"
                :class="{ 'pointer-events-none': badgeProgress !== 1 }"
              />
            </div>
          </div>
        </div>
      </div>

      <!--      Жижа-->
      <div class="bg-teal-100 w-full h-[300px]">
        <p>Жижа</p>
        <p>Капля</p>
      </div>

      <div class="w-full h-[400px]">
        <Cup
          :cups="[
            {
              title:
                'Сайт рыбатекст поможет дизайнеру, верстальщику, вебмастеру сгенерировать несколько абзацев!',
              subtitle: '',
              backText: 'Справа больше кружек!',
            },
            { title: 'World2', subtitle: 'test', backText: '' },
            { title: 'Severance3', backText: '' },
          ]"
        />
      </div>

      <div class="p-12 w-full grid place-items-center">
        <span class="text-2xl">Footer</span>
      </div>
    </section>

    <a href="https://github.com/khusainovrm/severance" target="_blank" class="git-icon">
      <img src="../assets/git.svg" alt="git" />
    </a>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue';
import * as THREE from 'three';
import gsap from 'gsap';
import ScrollTrigger from 'gsap/ScrollTrigger';
import chair1 from '../assets/char1.png';
import chair2 from '../assets/char2.png';
// import Badge from './BadgeScroll.vue';
import vertexShaderCode from './shaders/vertex.glsl?raw';
import fragmentShaderCode from './shaders/fragment.glsl?raw';
import HorizontalCarousel from './HorizontalCarousel.vue';
import { isMobile } from './utils.ts';
import Cup from './Cup.vue';

const START_BADGE_OFFSET = 250;
const BAGE_MOVE = 175;

gsap.registerPlugin(ScrollTrigger);

// ScrollTrigger.config({ ignoreMobileResize: true }); // fix issue with viewport on resize
ScrollTrigger.normalizeScroll(isMobile()); // mobile address bar will always be present

const canvas = ref<HTMLCanvasElement | null>(null);
const sceneSection = ref<HTMLElement | null>(null);

let camera: any;
let renderer: any;
let rafId = 0;
let timeline: any = null;
let animateCoffee = false;
let badgeProgress = 0;

const badgeTriggerAnimationRef = ref<HTMLElement | null>(null);
const badgeRef = ref<HTMLElement | null>(null);

const stringHeight = ref(0);
const badgeOffset = ref(-START_BADGE_OFFSET);

const targetHeight = ref(0);
const targetOffset = ref(-START_BADGE_OFFSET);

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
  // canvas
  if (!canvas.value) {
    return;
  }
  const width = window.innerWidth;
  const height = window.innerHeight;

  const scene = new THREE.Scene();
  scene.background = new THREE.Color('#305361');

  camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 100);
  camera.position.set(0, 0, 7);

  renderer = new THREE.WebGLRenderer({ canvas: canvas.value, antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setSize(width, height, false);

  // Фон градиент
  const geometryBackground = new THREE.PlaneGeometry(60, 20);
  const materialBackground = new THREE.ShaderMaterial({
    uniforms: {
      color1: { value: new THREE.Color('#305361') },
      color2: { value: new THREE.Color('#4c6b7c') },
    },
    vertexShader: `
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
  `,
    fragmentShader: `
    uniform vec3 color1;
    uniform vec3 color2;
    varying vec2 vUv;
    void main() {
      gl_FragColor = vec4(mix(color1, color2, vUv.y), 1.0);
    }
  `,
  });
  const background = new THREE.Mesh(geometryBackground, materialBackground);
  background.position.set(0, 0, -5);
  scene.add(background);

  // === Двери (рамка) ===
  const doorMat = new THREE.MeshBasicMaterial({ color: '#1f1f1f' });

  function createDoorFrame(width: number, height: number) {
    const geom = new THREE.PlaneGeometry(width, height);
    return new THREE.Mesh(geom, doorMat);
  }

  const doorLeft = createDoorFrame(0.97, 2);
  const doorRight = createDoorFrame(0.97, 2);
  doorLeft.position.set(-1.5, 2, 0.01);
  doorRight.position.set(1.5, 2, 0.01);

  const doorsGroup = new THREE.Group();
  doorsGroup.add(doorLeft, doorRight);
  scene.add(doorsGroup);

  // behind the door
  const doorMat2 = new THREE.MeshBasicMaterial({ color: '#d9d9d9' });
  const doorGeom2 = new THREE.PlaneGeometry(2.02, 2.04);
  const behideDoor = new THREE.Mesh(doorGeom2, doorMat2);
  behideDoor.position.set(0, 2, 0);
  doorsGroup.add(behideDoor);

  // === Нить (привязана к лифту) ===
  const lineMat = new THREE.LineBasicMaterial({ color: '#d9d9d9' });
  const lineGeom = new THREE.BufferGeometry().setFromPoints([
    new THREE.Vector3(0, 2, 0),
    new THREE.Vector3(0, -20, 0),
  ]);
  const line = new THREE.Line(lineGeom, lineMat);
  scene.add(line);

  // === Световая дорожка (трапеция, статичная) ===
  const shape = new THREE.Shape();
  shape.lineTo(1.0, 1);
  shape.lineTo(5, -10);
  shape.lineTo(-5, -10);
  shape.lineTo(-1.0, 1);
  shape.lineTo(1.0, 1);

  const lightGeom = new THREE.ShapeGeometry(shape);
  const lightMat = new THREE.MeshBasicMaterial({
    color: '#ffffff',
  });
  const lightOfCone = new THREE.Mesh(lightGeom, lightMat);
  scene.add(lightOfCone);

  // Кресла
  const textureLoader = new THREE.TextureLoader();
  const textureChair1 = textureLoader.load(chair1);
  const textureChair2 = textureLoader.load(chair2);
  textureChair2.wrapS = THREE.RepeatWrapping;
  textureChair2.wrapT = THREE.RepeatWrapping;
  textureChair2.repeat.x = -1;
  const geometry = new THREE.PlaneGeometry(1, 2);
  // const material = new THREE.MeshBasicMaterial({
  //   side: THREE.DoubleSide, wireframe: false, map:
  //   colorTexture,
  // });
  const materialChair1 = new THREE.MeshBasicMaterial({ map: textureChair1, transparent: true });
  const materialChair2 = new THREE.MeshBasicMaterial({ map: textureChair2, transparent: true });
  const char1 = new THREE.Mesh(geometry, materialChair1);
  const char2 = new THREE.Mesh(geometry, materialChair2);
  char1.scale.set(2, 2, 2);
  char2.scale.set(2, 2, 2);

  char1.position.set(-10, -1, 0.2);
  char2.position.set(10, -1, 0.2);
  scene.add(char1, char2);

  // Bottom portal
  const bottomPortal = new THREE.Mesh(
    new THREE.PlaneGeometry(2.5, 2.5),
    new THREE.MeshBasicMaterial({ color: '#ffffff' }),
  );
  bottomPortal.position.set(0, -8, 0);
  const angleDegrees = -90;
  const angleRadians = THREE.MathUtils.degToRad(angleDegrees);
  // Поворот вокруг оси X
  bottomPortal.rotation.x = angleRadians;
  scene.add(bottomPortal);

  // Кофейная жижа
  const geometryCoffeeLiquid = new THREE.PlaneGeometry(5, 5, 1, 1);
  const materialCoffeeLiquid = new THREE.ShaderMaterial({
    uniforms: {
      u_time: { value: 0 },
      u_color: { value: new THREE.Color('rgb(0,0,0)') }, // кофейный коричневый
      u_lightDir: { value: new THREE.Vector3(-0.3, 0.7, 1.0).normalize() }, // свет сверху
    },
    vertexShader: vertexShaderCode,
    fragmentShader: fragmentShaderCode,
    transparent: true,
  });
  const coffeeLiquid = new THREE.Mesh(geometryCoffeeLiquid, materialCoffeeLiquid);
  coffeeLiquid.position.set(0, 0, 0.01);
  coffeeLiquid.rotation.z = THREE.MathUtils.degToRad(-180);
  coffeeLiquid.visible = false;
  scene.add(coffeeLiquid);

  // Scroll-driven timeline
  timeline = gsap.timeline({
    scrollTrigger: {
      trigger: sceneSection.value,
      start: 'top top',
      end: () => '+=' + window.innerHeight * 4, // динамическая длина скролла относительно вьюпорта
      pin: true, // фиксируем секцию пока идет анимация
      // markers: true,
      anticipatePin: 1,
      invalidateOnRefresh: true,
      scrub: 1,
      // snap: {
      //   snapTo: 'labels', // скролл по меткам
      //   duration: { min: 1, max: 2 },
      //   ease: 'power1.inOut',
      // },
      // markers: true, // общие маркеры начала/конца
    },
  });

  // 0. Задержка 2 секунды
  // timeline.addLabel('step0');
  // timeline.to({}, { delay: 2 }, 0);

  // 1. Закрытие дверей + схлопывание дорожки
  timeline.addLabel('step1');
  timeline.to(doorLeft.position, { x: -0.5, duration: 1 }, '>');
  timeline.to(doorRight.position, { x: 0.5, duration: 1 }, '<');
  timeline.to(lightOfCone.scale, { x: 0, duration: 1 }, '<');
  timeline.to(lightOfCone, { visible: false, duration: 1 }, '<');

  // 2. Лифт едет к центру экрана
  timeline.addLabel('step2');
  timeline.to(doorsGroup.position, { y: -1, delay: 2, duration: 1 }, '>');

  // 3. Линия едет вверх
  // timeline.addLabel('step3');
  timeline.to(line.position, { y: 20, duration: 6 }, '>');

  // 4. Появление люка в полу
  // timeline.addLabel('step4');
  timeline.to(bottomPortal.position, { y: -4, duration: 1 }, '>');

  // 5. Появление стульев
  timeline.addLabel('step5');
  timeline.to(char1.position, { x: -2, duration: 3 }, '>');
  timeline.to(char2.position, { x: 2, duration: 3 }, '<');

  // 6. Лифт уезжает под землю
  timeline.addLabel('step6');
  timeline.to(doorsGroup.position, { y: -5.5, duration: 3 }, '>');
  timeline.to(
    line.position,
    {
      y: 16,
      duration: 3,
      onComplete: () => {
        animateCoffee = true;
      },
    },
    '<',
  );

  // Скролл для вытягивания нитки и бейджа
  gsap.to(badgeTriggerAnimationRef.value, {
    scrollTrigger: {
      // markers: true,
      trigger: badgeTriggerAnimationRef.value,
      start: 'start center',
      end: 'center center',
      scrub: true,
      onUpdate: (self) => {
        if (badgeProgress < self.progress) {
          targetHeight.value = BAGE_MOVE * self.progress;
          targetOffset.value = -START_BADGE_OFFSET + BAGE_MOVE * self.progress;
          badgeProgress = self.progress;
        }
      },
    },
  });
  // сглаживание (работает на каждом кадре GSAP)
  gsap.ticker.add(() => {
    stringHeight.value += (targetHeight.value - stringHeight.value) * 0.15;
    badgeOffset.value += (targetOffset.value - badgeOffset.value) * 0.15;
  });

  // === Рендер цикл ===
  function animate() {
    rafId = requestAnimationFrame(animate);
    // камера всегда смотрит на лифт, пока он едет
    // camera.position.y = liftGroup.position.y;
    // camera.lookAt(0, liftGroup.position.y, 0);

    char1.visible = char1.position.x >= -5 && char1.position.x <= 5;
    char2.visible = char2.position.x >= -5 && char2.position.x <= 5;

    if (animateCoffee) {
      materialCoffeeLiquid.uniforms.u_time.value = performance.now() / 1000;
    }

    renderer.render(scene, camera);
  }

  animate();

  window.addEventListener('resize', onResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', onResize);
  if (rafId) cancelAnimationFrame(rafId);
  if (timeline) {
    if (timeline.scrollTrigger) timeline.scrollTrigger.kill();
    timeline.kill();
    timeline = null;
  }
  // Dispose renderer to free WebGL context
  if (renderer) {
    renderer.dispose?.();
  }
});
</script>

<style scoped>
.scene-section {
  height: 100dvh;
  position: relative;
  overflow: hidden;
}
canvas {
  width: 100%;
  height: 100%;
  display: block;
}
.content {
  min-height: 200dvh;
}
.block {
  min-height: 100dvh;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
}

.git-icon {
  position: fixed;
  top: 20px;
  left: 20px;
  width: 50px;
  height: 50px;
  z-index: 2;
  filter: invert(1);
}

.cards-section {
  position: relative;
  color: white;
}

.cards__spacer {
  height: 100dvh;
}

.card {
  flex: 1;
  background: #333;
  padding: 40px;
  text-align: center;
  border-radius: 8px;
}

.badge-wrapper {
  position: absolute;
  top: 0;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column;
  align-items: center;
}

.string {
  width: 2px;
  background: white;
  visibility: hidden;
}

.badge {
  width: 100dvw;
}
</style>
