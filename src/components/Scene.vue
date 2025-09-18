<template>
  <div>
    <!-- Секция со сценой -->
    <section ref="sceneSection" class="scene-section">
      <canvas ref="canvas"></canvas>
    </section>

    <!-- Обычный контент после анимации -->
    <section class="content">
      <div class="block">Первый блок</div>
      <div class="block">Второй блок</div>
      <div class="block">Третий блок</div>
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

gsap.registerPlugin(ScrollTrigger);

const canvas = ref<HTMLCanvasElement | null>(null);
const sceneSection = ref<HTMLElement | null>(null);

let camera: any;
let renderer: any;
let rafId = 0;
let timeline: any = null;
let resizeTimer: number | null = null;

const onResize = () => {
  if (!canvas.value || !renderer || !camera) {
    return;
  }
  const { width, height } = canvas.value.getBoundingClientRect();
  // Update camera
  camera.aspect = width / height || 1;
  camera.updateProjectionMatrix();

  renderer.setSize(width, height, false);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));

  // Debounce ScrollTrigger refresh to avoid thrashing during mobile UI show/hide
  if (resizeTimer) window.clearTimeout(resizeTimer);
  resizeTimer = window.setTimeout(() => {
    ScrollTrigger.refresh();
  }, 150);
};

onMounted(() => {
  if (!canvas.value) {
    return;
  }
  const { width, height } = canvas.value.getBoundingClientRect();

  const scene = new THREE.Scene();
  const axesHelper = new THREE.AxesHelper(5);
  // scene.add(axesHelper);
  scene.background = new THREE.Color(0x000000);

  camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 100);
  camera.position.set(0, 0, 7);

  renderer = new THREE.WebGLRenderer({ canvas: canvas.value, antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.setSize(width, height, false);

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
  shape.lineTo(2, -10);
  shape.lineTo(-2, -10);
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

  // Scroll-driven timeline
  timeline = gsap.timeline({
    scrollTrigger: {
      trigger: sceneSection.value,
      start: 'top top',
      end: () => '+=' + window.innerHeight * 4, // динамическая длина скролла относительно вьюпорта
      scrub: true,
      pin: true, // фиксируем секцию пока идет анимация
      // markers: true,
      anticipatePin: 1,
      invalidateOnRefresh: true,
    },
  });

  // 0. Задержка 2 секунды
  timeline.to({}, { delay: 2 }, 0);

  // 1. Закрытие дверей + схлопывание дорожки
  timeline.to(doorLeft.position, { x: -0.5, duration: 1 }, '>');
  timeline.to(doorRight.position, { x: 0.5, duration: 1 }, '<');
  timeline.to(
    lightOfCone.scale,
    { x: 0, duration: 1, onComplete: () => console.log('door closed') },
    "<'",
  );
  timeline.to(lightOfCone, { visible: false, duration: 1 }, '<');

  // 2. Лифт едет к центру экрана
  timeline.to(
    doorsGroup.position,
    {
      y: -1,
      delay: 2,
      duration: 1,
      onStart: () => {
        console.log('lift move');
      },
    },
    '>',
  );

  // 3. Линия едет вверх
  timeline.to(line.position, { y: 20, duration: 6 }, '>');

  // 4. Появление люка в полу
  timeline.to(bottomPortal.position, { y: -4, duration: 1 }, '>');

  // 5. Появление стульев
  timeline.to(char1.position, { x: -2, duration: 3 }, '>');
  timeline.to(char2.position, { x: 2, duration: 3 }, '<');

  // 6. Лифт уезжает под землю
  timeline.to(doorsGroup.position, { y: -5.5, duration: 3 }, '>');
  timeline.to(line.position, { y: 16, duration: 3 }, '<');

  // === Рендер цикл ===
  function animate() {
    rafId = requestAnimationFrame(animate);
    // камера всегда смотрит на лифт, пока он едет
    // camera.position.y = liftGroup.position.y;
    // camera.lookAt(0, liftGroup.position.y, 0);

    char1.visible = char1.position.x >= -5 && char1.position.x <= 5;
    char2.visible = char2.position.x >= -5 && char2.position.x <= 5;

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
  height: 100vh;
  position: relative;
  overflow: hidden;
}
canvas {
  width: 100%;
  height: 100%;
  display: block;
}
.content {
  min-height: 200vh;
  background: #f0f0f0;
}
.block {
  height: 100vh;
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
</style>
