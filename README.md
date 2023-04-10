# FinalBurn Neo WASM

[Example](https://github.com/mantou132/nesbox/blob/dev/packages/arcade/src/index.ts):

```ts
import init from '@mantou/fbneo/fbneo-arcade';
import wasmURL from '@mantou/fbneo/fbneo-arcade.wasm?url';

import { Controllers } from './input';

const INT16_MAX = 2 ** 15 - 1;

export class Arcade {
  #frameNum = 0;
  #currentFrame = new Uint8ClampedArray();
  #fbneo: undefined | Awaited<ReturnType<typeof init>> = undefined;

  #width = 0;
  #height = 0;
  #vidBits = 32;
  #audioArray = new Int16Array();
  #controllers = new Controllers();
  #statePath = '';

  async load_rom(bytes: Uint8Array, filename = '') {
    this.#frameNum = 0;
    let resolve: (value: unknown) => void = () => void 0;
    const romReady = new Promise((res) => (resolve = res));
    this.#fbneo =
      this.#fbneo ||
      (await init({
        start: () => {
          this.#fbneo!.cwrap('startMain', 'number', ['string'])(filename);
        },
        locateFile: (path, prefix) => {
          if (path === 'fbneo-arcade.wasm') return wasmURL;
          return prefix + path;
        },
        setRomProps: (w, h, rotateGame, flipped, vidImageDepth, _nBurnFPS, _aspectX, _aspectY) => {
          this.#width = w;
          this.#height = h;
          this.#vidBits = vidImageDepth;
          resolve(null);
        },
        setVisibleSize: (_pnWidth, _pnHeight) => {
          //
        },
        setAspectRatio: (_pnXAspect, _pnYAspect) => {
          //
        },
        audioCallback: (soundPtr, length) => {
          this.#audioArray = new Int16Array(this.#fbneo!.HEAP16.buffer, soundPtr, length);
        },
        drawScreen: (vidImagePtr) => {
          const pixelCount = this.#width * this.#height;
          this.#currentFrame = new Uint8ClampedArray(pixelCount  * 4);
          if (this.#vidBits === 16) {
            const b = new Uint8Array(this.#fbneo!.HEAP8.buffer, vidImagePtr, pixelCount << 1);
            let index = 0;
            for (let i = 0; i < pixelCount; i++) {
              const offset = i << 1;
              const color = ((b[offset + 1] << 8) & 0xff00) | (b[offset] & 0xff);
              currentFrame[index++] = ((color >> 11) & 0x1f) << 3;
              currentFrame[index++] = ((color >> 5) & 0x3f) << 2;
              currentFrame[index++] = (color & 0x1f) << 3;
              currentFrame[index++] = 255;
            }
          } else {
            const b = new Uint8Array(this.#fbneo!.HEAP8.buffer, vidImagePtr, pixelCount << 2);
            let index = 0;
            for (let i = 0; i < pixelCount; i++) {
              const offset = i << 2;
              currentFrame[index++] = b[offset + 2];
              currentFrame[index++] = b[offset + 1];
              currentFrame[index++] = b[offset];
              currentFrame[index++] = 255;
            }
          }
        },
        addFile: (_RomName, _nType, _nRet) => {
          //
        },
        addInput: (_szName, _key) => {
          //
        },
        addArchive: (_szName, _szFullName, _bFound) => {
          //
        },
      }));

    // https://github.com/mantou132/FBNeo/blob/nesbox/src/burner/sdl/run.cpp#L109
    this.#statePath = `/libsdl/fbneo/states/${filename}.fs.all`;
    this.#fbneo.FS.mkdir('roms');
    this.#fbneo.FS.writeFile('roms/' + filename + '.zip', bytes);
    this.#fbneo.start();

    await romReady;

    this.#controllers = new Controllers();
  }
  clock_frame(): number {
    this.#fbneo!._collectGameInputs();
    this.#fbneo!._doLoop();
    return this.#frameNum++;
  }
  audio_callback(out: Float32Array) {
    for (let i = 0; i < out.length; i++) {
      out[i] = (this.#audioArray[2 * i] + this.#audioArray[2 * i + 1]) / INT16_MAX / 2;
    }
  }
  handle_button_event(player: Player, button: Button, pressed: boolean) {
    const controller = this.#controllers.getController(player);
    controller.handleEvent(button, pressed);
    this.#fbneo?._setEmInput(...controller.getArgs());
  }
  state(): Uint8Array {
    this.#fbneo!._saveAllState(1);
    return this.#fbneo!.FS.readFile(this.#statePath);
  }
  load_state(state: Uint8Array) {
    this.#fbneo!.FS.writeFile(this.#statePath, state);
    this.#fbneo!._saveAllState(0);
  }
  reset() {
    this.#fbneo!.start();
  }
}
```