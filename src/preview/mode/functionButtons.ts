import * as SVG from "svgjs";
import { pathlikeof } from "../utils/svgjs/pathlikeutils";


/**
 * Duplicate button event
 */
export function duplicateEvent(svgroot: SVG.Doc) {
  let targets = svgroot.select(".svgeditor-handtarget");
  targets.each((i, elems) => {
    elems[i].clone();
  });
}

export function deleteEvent(svgroot: SVG.Doc) {
  let targets = svgroot.select(".svgeditor-handtarget");
  targets.each((i, elems) => {
    elems[i].remove();
  });
}

export function forwardEvent(svgroot: SVG.Doc) {
  let targets = svgroot.select(".svgeditor-handtarget");
  targets.each((i, elems) => {
    elems[i].forward();
  });
}

export function backwardEvent(svgroot: SVG.Doc) {
  let targets = svgroot.select(".svgeditor-handtarget");
  targets.each((i, elems) => {
    elems[i].backward();
  });
}

export function reverseXEvent(svgroot: SVG.Doc) {
  let targets = svgroot.select(".svgeditor-handtarget");
  targets.each((i, elems) => {
    elems[i].x(elems[i].x() + elems[i].width());
    elems[i].width(-elems[i].width());
  });
}

export function reverseYEvent(svgroot: SVG.Doc) {
  let targets = svgroot.select(".svgeditor-handtarget");
  targets.each((i, elems) => {
    elems[i].y(elems[i].y() + elems[i].height());
    elems[i].height(-elems[i].height());
  });
}

export function deleteVertexEvent(svgroot: SVG.Doc, vertexNumber: number) {
  let targets = svgroot.select(".svgeditor-handtarget");
  targets.each((i, elems) => {
    pathlikeof(<any>elems[i]).removeAt(vertexNumber);
  });
}

export function duplicateVertexEvent(svgroot: SVG.Doc, vertexNumber: number) {
  let targets = svgroot.select(".svgeditor-handtarget");
  targets.each((i, elems) => {
    pathlikeof(<any>elems[i]).duplicateAt(vertexNumber);
  });
}
