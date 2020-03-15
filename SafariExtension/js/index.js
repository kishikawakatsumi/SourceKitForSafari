const GitUrlParse = require("git-url-parse");
const tippy = require("tippy.js");
const marked = require("marked");
const hljs = require("highlight.js");

const symbolImages = {
  s:
    "data:image/png;base64,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",
  c:
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAMKADAAQAAAABAAAAMAAAAADbN2wMAAAFEklEQVRoBe1aTW8bRRh+/O3YiRM3TSBpSQtpKAhKckEBiaaIlAMgvk69IHGCX8CBn8ABiV/AiQPiAOL7AA1qEiRAlaiCUEXSJFRtkqZOYzvOxo6/eZ9Vx7vrOLHjXRIH8Uij2ZmdnX2emXffecdjF2qgXC6PS/UlSWOSTkhql3QY0OSly5KmJH3mcrkm9iQhxIckXZHUqiC3IbMIlyrIjfNy/ZWkqKpr0TwhvF6X2ZgmP13AfVW/SVknL2XMfHkLixNxbN0poJgts+2BwxNwIdznxSPjxzD8xgCEtOJAEaNSvqEEXJGKC7y7uZbBTx/MIjGbY7FlED3rxwvvn0VHT5viNCkCnnfJaPODvcxajvzX7820HHnFmCJe+3DYPBMXvXKT3kYHzUaNPKerqzeC9mgIHq9HNTnQvFgoQkukkYyl9MElN3IcefOU4nHJLVd0lTpo8wok39nTcWjkyYMDRw7komDmKHVjFEA/r4MfrAJHvlVg5mLmKPxOUEBlkTJ7m8Mym1qDZuZi5kjuFHCk8b+Aw54+utF/BYEuD9plFQ31eJFNlZCOFZBeK6CUd3ZVd1RAW7cHZ17tROdpP7zBndbJhTJxI4uF71PYWjU8np0RdExA/zMhDL4cgce/k7giyMXx2KNBRM8EcOdqGvPfpmzPiCMCnngrip4nKzGK4rtr7nK70D8a1mfp+qeMy5qHbQE954I1ycf+yCAxn4W2koc/4kGXmFX/s2F4fJWIEr3DbUgt5bA0vdW0AlsC3PL04CvGMk8WpUIZs58ncfdaxkQqj/Xr21j+ZQsj73YjGDVeO/hSBDFpm9NKpvaNX+5usA308dCFdgS7DDJ8ZOG7VBV5o6PtRBF/fhJHuWR4IppTdChgNNrnlS0Bxx8PWl6XTRXl49zbHLSVAhIL1r2GHQHW4bPQqV9oEx9vBj1LqQHvePOHFOJz/sqj+a3mzIcdWBlUuqx/4Y+44Q1YJ5ALVSNI3c6DyQlYGeyjR66w1diONyag+jk75aYFBMQ1VsOOKVT31Wi5aQH0KNWgvz9oNC2glr0HowcvYKchNziENJd8ugRfyBiD9j4f7sK8gNXujN9P+EHj1cVcGfHZbO3GdWqNXuo0rHU7c68A34DhDvueDuHm5c26P4Rx9e5+zFhDYjOZpgUYw1eLYZ261WtpSwuG0CefC1vqqgv8pa164Vr/a7u6WcNlWwJWfk1DW7X689MXO3BqvPI7gYVIqNeLc293w+0xAjqGFfG55syHndsyIUhIM//NBkbeOV4hypj/4RfFRCTMSC7moC3n4Qu7ERnwofepNjD2MYObGzvu154AYZKUuObWlIaBMeuoR076wbQXVn9PY+nnvWOnvZ7nPVsmpDpflFGc+Xgd2Y2da4NqY84Zct+e1jD3RdJc3dS17RlQb+Ve9+pHMfAbiMjmJfyAz7J5YbucVtS9zd8/biKbbEys6n+33DEBfEFhu6zvc/WXialzk0+fz81KRgI93ncajgqwkBOumXtFPVnqHS448g04zGlf3f0nBPAoUwfPpBR4uNAqMHMxcxR+GmeA57A6uMwr8GSkVWDmYuYo/JYpYEoR5WmgAo91NtYkMDvEmeC7yYFcFMwcpW7qyB/yuSV2mRAlk1TIOIZHmTwNbDWoY1ZyvI9JctdL8qsxj++P7kE3FYmI85Idub8aVNYBmY5pETAqSTcnyVsR5Ma/GJCrjopBqQrmMhvjkvEAvOX/bvMPWGZxrZu3MDMAAAAASUVORK5CYII=",
  i:
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAMKADAAQAAAABAAAAMAAAAADbN2wMAAAEMElEQVRoBe1aS08TURQ+05Z3EctDqSgafKBhgQsVNT6IuHHha4ULf4YLfoIL/4Ebl7ox4spEMTyiCSsFNAQxSiwPoWgtbWkZ2o7nG7jTwQ6lZTp0aviSm+k9987c7zv3OT0jkQEUReliczenK5yaOLk5FQJhbnSG0yCnZ5Ik9WUkwcSPc+rnZFeA23G9CElkuOAy/+7l5BE2m14DzOs298YQ+KkC1lUNc14lz3kaefGDvvX9pshcnBIrCuruOJxlElV5XdTSVUvtd5qJSQsOENHB+UkhoJ8NV1Ea8kfp7cMJCkzIyNoGntZSutbTStUNFYLTAAvolNjbmLBvYIXnXz4YsR15wRgibj1q1/fEdRcXYrVRgWEjPI/u2rtvD7k9leR0OUWVHb0m4gkKB5bpz8KS6lxwA8fTdw8LHt0O/oWlUgXGvADI1zRUF4w8eMBx4AAuAnqObLsCAVjnVWDCCsDzdoGei54j82uCAG2T0q82hRo2Rk7Tc9FzBHcIKGrsCih092EZzRql1Q5ylGi7oeF98lKCkqm1wLBOPo05CTh1z0Oeo2UZ21eSCkV/8fr9c5V8/WEKzaxmrG+2MCcB2TQmOSSqbHCpqaGtnKbfR+j7qyXLesXSSQwxhy65qeVGaiPKxgm51DHVA6FpmabfRdba46lRVsM755FSqmst38Ch6WIV+cdiFJzK/wHRlIDYnwTNf4huIItMPQ+dtvse7dCFc1Vzp5vGnqSOKmk3bdNgSsBmbS5+jtHCaIz2t2tHX3J7S7Tq6JHaE6nFYGE0qjriINsbz1QSVjvfUIR8A3ijzAxLBKDJ4NTKBgEYXq4KieJRhaoaXVR3MjXMwrOr5D1bScdu1mhsISIbWCYguZr+FudwYQ9Jt5fwiebA+aps+KbVsUyAfsigVTmSIDmUTCMAg5eHDVasZFyhyALvgvxilZTThRrdbImAinonec9t9Gh4dvPtGeQDX1do/GmA5LCxSCPysJkS4CyVqGzv2tsa3rfxG8to81U3Of85cswNry+3BkwScnJb5E0LqD1RThd6UpPRgJtqmv+4TP5Psc2K+dgRz9nz4mHZTXVRexvXxfEYTfYGM94pBxMZyzMVmhpCmz0YBzpMxqnXIcKesBWym67GTzElYMknk28wtdkoPP9iv+O07I9bdnj7V4YpASvc9TjjFBKWzwGrxe0KsNrDWz1/twe28pDV5TmtQiOPf+WFz5fnQULKB3aHUD68aOYZ/0UPaGcBxKQEEFywC/Rc9ByZXxg9gDisCgTUBBAZsQv0XPQcmd8MBAwKoogGCiCsE/SHSK9elO3UFW2DA7gI6DmybbDog3wO/tMJ4fsBKMQfUAhlIhpoN4gwKziuYwDc1VzRB7qhiEUU5acG2j7A3YFvDzo4qcMJomwIcMMnBuCqQhtQwoDrevS+KD63+QvyMSHGdKACIAAAAABJRU5ErkJggg==",
  p:
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAMKADAAQAAAABAAAAMAAAAADbN2wMAAADr0lEQVRoBe2ay08TURTGvyJFeanIIypgYgyYKAtdKNEExMdKTHQlbozGvY8/wIVx58LEaIwroyQuNHFj4lIUSoIPEt24gkAQ0pjwVFoBaaGeb+C2t7R2WpmZTk1PcjNzz72d+X137px7M6ceJLFIJHJS3B1SWqXUSimTkg0Lyk39UnxSXng8nq6UEALeIKVbiluNbA26CI+qSEOLnL+SUqF8Lj3OCNdZeRq95DMErKr6KHUDfjkSwYN3QTztj2BgagPmQlGd/I1jVuKNoLFyCZcPeXD1eBkKPFEOimgWEYNKQLc4jpFsbDqMC52/0DfqZdU1dnRXCM8vlaJ+W6Fi6hEBbR4Zfb6wb+jlyLfcm3UdvCKmiN4bm/UncYpyGG0M47RRIy/q0FjlRW15ITZFRauezhwXwhKCAmEMTIYgA22wkfH6iXIF0FEgZwyVhnHOKyP8norswZODA0cGsijTGcXXSgGM84bxhVXGkXeL6Sw6o/DVUkB0kdKjTbamTbJB01l0RrJTQE5bXkC2H58lb6pX3v3K0tRSFiUkTs+l7vMvrZYI2FsD3Dlnfvvgb+DbNPB5DHj5BQgvm//GrIej70DZRmD/DuDiYeDheWDfdjM883ZHBeg4dbJtvH0GqIkGcb01/XNLplCy23XK3nYisNJSXCQrzhagTXbyW0tivYtlgb3WBtx8HfNlemabgE8jwIjMd92e9QO3TgNNO2Peg/VAQzUwOBHzZXLm6BSaDwH3exLxdlcl+tL1OCqAUP4fwM/5eLzdlfH1TGqOCyDc4lI8YlFsDxnfkEbNcQEMpdVrIs/wVBqkf+niuIArRxJJhicTfel6bItC3FrMLa5gqDDa3gQcqItHG5LoMzAe78ukZpsALlJmFpJ34e5bYGkdWwrbBJjBBxZkO+Fb2RuZ9U3V7riAgGzo3g8DTz4AsyJivWabgMd9wDi/bK4ad6KjsjJbvaW2TQC3zGu3EkqMlUfHw6iV8LxWXoDVI5rp9fJPINMRs7q/JVHo63eg/ZHVaOldLz+F0hsn+3r9F08guuAzJ6WMyQW3mM6iMwpfkE/Ar0CZUFPGzIhbTGfRGYXPTwE+BcpsoDKmdYZmwtDVqzanjrw3GciiTGcUny/nk3ySejXS98bXGuZhmcpkNtBtptKsWq6YadYulSeWj37I3UQ3RztX/2oQXQfkcfSKjmYpST7+UaIrjGz8iwFZDTOmkKqo42r2ngnwVilMw675FKV62n7kGsUwz0iZ9O82fwCKV7qEiQ3d4AAAAABJRU5ErkJggg==",
  m:
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAMKADAAQAAAABAAAAMAAAAADbN2wMAAAETElEQVRoBe1aS09UMRQ+FxgfvBIEEUMgGGRAXWk0JEQQAYW40R3udKFLo/4M3WjiH9CFRpdsxERQHkElbowGHyhq1AHii6eIzsB4votn2oFhnp2ZS8JJOm1Pe9vva3va3nvGohDi9/ubWd3OoYFDKYdcDumQWe7Uw6GPwx3LsrrDgmDgVRx6ODhVgK1KJ2FJhgvqOd3BoUB0Do0nGNdxno1+4LMJ/Gc1yHkb/KLfT9ceztL1p34a/pFJc94ATzyTMsl2+clduECnD1h07nAuZVgBHCBRyyTeCoEeVhwCss8/fXTyxi969MmFrGOkrtxLt0/lUNmWLMHUywQaLR59GGwXtBj5+qvTjgMviEGi/0K+PhMtoIPdxhYsGxl5ZkfuIheV5mXRpgBpqZmaeN7HW9CMj4a/e4kH2sYGjOeb8gRAewansFXagjUvAvCVBekDDxwYOGAAFhEdI+saQAD7vC0wWBGMvFNEx6JjZHylIBA4pPTdJl3LJtSg6Vh0jMAOAmta1gmke/pitlQX23lhTjDsRd68vs4E6yLlSvJX1vjGV7eFxZX6cJqYCVQXE106Edwkb9F09hbR2HSwfrXcnu1El5e1gbpnbkbfhrRtxAZwRWndLU1Gjlt3Ra4TbQ0jBNBZSzVRZhSt5WwgOlgZLbzI9aLoMnIjqFGQzdfDish1m9xEG2NeuKu3a4wAumiLYmm0xbDUVoetSowS2FtGVBw411UnksIGUFEoOTNxwgTmvQpIBhvz0TCzsHz09WdVK7GlEibwfJRoXNs+j9QQ39dXgtjMF8qGnUr/apxfniZVPt5UwgRwBtx7qbov4iW0v1zlJdVYxddjdSumTu0ZqRNPnDABdHr/NZFvQXW/fKmgRNfN/CHqf6fqJ5IyQmDyN9GTjwoGZkC/blQWEe3cqsofvCH6qxFWJbGnjBBAt/qSwIEGWxDRRx86va7UiTc2RuDZF6LRKQUDuxFsGYcW1r/I0BgbLz6KGBJjBIBHN+Zt/N69j88F7DzZfH0Q6RySlJnYKAEYs1db27jg6afz9Dwb74gZ4NKKUQIA+PiDNE1Ut4OopkTlu9l4fTHe99XToVNGCaALfYmoL4FLnZs0XqFjnABOZk+IE/bFKnoBEm9snACAhBppfWbiBRvquaQQ6FpmzFN80A28D9V94rqkEMBVYUDbbbqSYLxCHV+n+Tq2JNbFOUnSMTe/YjlI7g4rbP4rCltSZiCVvNcJpHK0Q/WFGYAr0xb4pETgXHCK6Fh0jIxvFgQ8AhQONRF4RpwiOhYdI+PzgECfAIU3UARunZEJH+nspSxVMfoGBmAR0TGyrm/NO/nY9Wq773vBEH5YuDLhDXSaiJtV8xXDzdptrxk+y/DONMhhbTq6MdpMop6jDiEBnUMl6K8GMGJbeDr6OVHLwV5OS1rH/QIb/mIArLbYS0gyEvNsNHMaDvAGDnDDhvniyaXJk4h/t/kHoInj/3HjULsAAAAASUVORK5CYII=",
  f:
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAMKADAAQAAAABAAAAMAAAAADbN2wMAAAC8ElEQVRoBe2aTWgTQRTH326bmgSx9hIpbUGoVfxA6Cknq6AXT4KXeLO3HntW8NSTx4IX8dST5GLxIF4sNPFUQQqCINhqwMbQoEZraEyiXd9/yAtDG9ZuMkl2Zf8w7M6bmc3vvflYwluLWshxnKtsTnGZ4TLG5SiXfqjMP5rnkuWStixrxRWCwae4rHLxq8A2pTthSYUbLvH9Uy4jYvPptcRcN3g2XoJPOdDwao3rCp7rtLSZpifF55SrbVFl7xf69lwxO0onh8bpZuI63Z5MEUMLA5xIcv29OLDKhstoLexu0/ybe7S++xZV32g6fp4WLy7QaPyEMGXYgSsWRxsb9gWsiHxqbc538EIMJ9LJh/pMXBvkRpw2Slg2EnmbV9fEkVFKDI7QkBWRLj291pw6FX+X6FO1QHvkKDYwzp66JRwpm+9wVCphzYsAPx5J9A0eHAgcGMAi0hnZNgMHcM4rYcOKEHm/SGfRGZlvDA40X1L6adOvZdMqaDqLzgh2OBBohQ70e/pwjBrR8cgwRWzvx+2X6lc+IJ22GYw5MDc5S2ePnfYMMr9+h37UdzyPkwHhHpBI9OtqbAntd6BQ2aZX317vNx+oV/9UD9i8GLrmwOdKgZbzz7ywtNU33ANthc3goHAGDAazrUd1bROfGz5DCxfuukIt5R7TRvmja59/NXbNgdhAjCbizb8aLTmiA9GWdi/GwO+Brs1AqfadNss512Du1H+6th+msWsOfGD4BxuPDsPQUZ/AL6HQgY7m38DgcAYMBLGjR4Qz0FH4DAw29h64/27RAI73R4RLyHvMzI74L2YAqUwl5KRESC74RTqLzsh8ZcwA8rBKSKiJkBnxi3QWnZH58nAgK6DIBoqQ1tmqF0n3Xtp6dcVvgwEsIp2RbdnAJ/lsTlUifZ+Bh3yvUpnIBvpNkmYFY0MZsEueGOn74Ca64RHniAP5qUHzPcDTgW8PklzUcoJTPhTY8ImB+k4CfM0FpcM2svdIgPv+c5u/iCGYBvniuQcAAAAASUVORK5CYII=",
  e:
    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAMKADAAQAAAABAAAAMAAAAADbN2wMAAADCElEQVRoBe1az2sTQRj9JtmitjGgxYNUTxLrRRBBC0qrYE+CeKzoxYM3EU/+E179BzyIP47SQ0EaaFMQxaMKYhQLmosBf8TEpjHJ+L1pJ05CNpt0d5Jd2QfDdmdmZ9775pvZtm8FdYGU8gJXL3CZ4zLFJcVlFCjzpAUuOS5PhBDZniSYeIbLCpewAtwypgihb7hhln9+ymWfrgvp9TvzusyrsQZ+SsC2qpd8r8hL2aTyq3sk392nZOk9ifpv9B06pDNOjfRREseuU+rULRIioTlAxAyLyGsBK1xxDq310meqLF6hseJz3IYGfw6coYlLj8lJH9acVlnAecHRx4ZdRi0iX3o4GzrymjFEpK+umSsx73AjThsFpM2/yAsSqQyJPXwIJXbrLsO9NqskNwoky3meVypu4Lj39G3NYwFJhaNSATmvochPHBkdeRDhwAnmAC4aJkeum4MAnPMK2LAaKvL6ZsRXk4vJkWlNQUDrJdV22owqbboFy+DSxpG5t86lbs9FoS4WMOpVwjHqD4kxEuOTA48hGzWijW8DP9f5gG8BYnKads3f7RzX875ZfEu15Tue/bw6xHvAK0K2232nUDeC9Q9LRFX8wugOWfnq3jhAixUBjfwiyR/rA9DYedd4D+w8dsE8GfkVsLIHkofOktw/3TPEjcILos2fPfv002hFgHP8mufczWfrJAMQEPkUirwAKym0uXST3wOfPNMoiA6WVkAGwa2vMSwJ6GvuQDrFAgIJo49BrGxi58QNohr+M+4O+esL1V8/cO/QZ4sVAcmDJz2nx19kFICAeA94htpyB98pJItvqProomWa7sPHKeQem+G0/Bcr0Dqw4Um1wOZCaGBwaeNIVMYKwIdVgKGmAWckLDC5mByZXwECcpoo3EAN2Dqy8pHIUK/bhnaFxcQctiymrVlNjlyTi7zJl2CrMstKVqEPPiysTLiBYYO2WQ2vGDZrVvvEcNGia3Qj2lH91KD1HuDlwLcHM1xUOkFUCAFu+MRAfScBfiqFOoluu/cwwEP/uc1fvv6eZvtrhukAAAAASUVORK5CYII="
};

marked.setOptions({
  highlight: function(code) {
    return hljs.highlight("swift", code).value;
  }
});

let popoverContent = null;

const normalizedLocation = () => {
  return document.location.href.replace(/#.*$/, "");
};

const readLine = (line, lineIndex, columnIndex) => {
  let nodes = line.childNodes;
  for (var i = 0; i < nodes.length; i++) {
    const node = nodes[i];
    if (node.nodeName === "#text") {
      var element = document.createElement("span");
      element.classList.add("symbol", `symbol-${lineIndex}-${columnIndex}`);
      element.dataset.lineNumber = lineIndex;
      element.dataset.column = columnIndex;
      element.dataset.parentClassList = `${node.parentNode.classList}`;
      element.innerText = node.nodeValue;
      node.parentNode.insertBefore(element, node);
      node.parentNode.removeChild(node);

      columnIndex += node.nodeValue.length;
    } else {
      node.classList.add("symbol", `symbol-${lineIndex}-${columnIndex}`);
      node.dataset.lineNumber = lineIndex;
      node.dataset.column = columnIndex;
      if (node.childNodes.length > 0) {
        readLine(node, lineIndex, columnIndex);
        columnIndex += node.innerText.length;
      }
    }
  }
};

const readLines = lines => {
  const contents = [];
  lines.forEach((line, index) => {
    contents.push(line.innerText.replace(/^[\r\n]+|[\r\n]+$/g, ""));
    readLine(line, index, 0);
  });
  return contents.join("\n");
};

const activate = () => {
  const location = normalizedLocation();
  const parsedUrl = GitUrlParse(location);
  if (!parsedUrl) {
    return;
  }
  if (parsedUrl.resource !== "github.com") {
    return;
  }
  if (!parsedUrl.owner || !parsedUrl.name) {
    return;
  }
  safari.extension.dispatchMessage("initialize", {
    resource: parsedUrl.resource,
    href: parsedUrl.href
  });

  if (parsedUrl.filepathtype !== "blob") {
    return;
  }

  const lines = document.querySelectorAll(".blob-code");
  const text = readLines(lines);

  safari.extension.dispatchMessage("didOpen", {
    resource: parsedUrl.resource,
    slug: parsedUrl.full_name,
    filepath: parsedUrl.filepath,
    text: text
  });

  let hoverTooltip;
  const onMouseover = e => {
    let element = e.target;

    if (hoverTooltip) {
      hoverTooltip.destroy();
      hoverTooltip = null;
    }

    if (!element.classList.contains("symbol")) {
      return;
    }
    if (element.dataset.parentClassList.split(" ").includes("pl-c")) {
      return;
    }

    safari.extension.dispatchMessage("hover", {
      resource: parsedUrl.resource,
      slug: parsedUrl.full_name,
      filepath: parsedUrl.filepath,
      line: +element.dataset.lineNumber,
      character: +element.dataset.column,
      text: element.innerText
    });
    safari.extension.dispatchMessage("definition", {
      resource: parsedUrl.resource,
      slug: parsedUrl.full_name,
      filepath: parsedUrl.filepath,
      line: +element.dataset.lineNumber,
      character: +element.dataset.column,
      text: element.innerText
    });
  };
  document.addEventListener("mouseover", onMouseover);

  let codeNavigation;
  safari.self.addEventListener("message", event => {
    switch (event.message.request) {
      case "documentSymbol":
        (() => {
          if (codeNavigation) {
            codeNavigation.destroy();
            codeNavigation = null;
          }

          const value = event.message.value;
          if (value && Array.isArray(value)) {
            const symbols = value.filter(documentSymbol => {
              return isNaN(documentSymbol.kind);
            });
            if (!symbols.length) {
              return;
            }

            const blobCodeInner = document.querySelector(".blob-code-inner");
            const style = getComputedStyle(blobCodeInner);

            const symbolNavigation = document.createElement("ul");
            symbolNavigation.style.cssText = `list-style: none; font-family: ${style.fontFamily}; font-size: ${style.fontSize};`;

            symbols.forEach(documentSymbol => {
              if (!isNaN(documentSymbol.kind)) {
                return;
              }

              const navigationItem = document.createElement("li");
              navigationItem.style.cssText = "margin: 10px 0;";
              const symbolLetter = documentSymbol.kind.slice(0, 1);
              const imageData = symbolImages[symbolLetter];
              const img = imageData
                ? `<img src="${imageData}" width="16" height="16" align="center" />`
                : symbolLetter.toUpperCase();
              navigationItem.innerHTML = `<a href="${parsedUrl.href}#L${documentSymbol.start.line}">${img} ${documentSymbol.name}</a>`;
              symbolNavigation.appendChild(navigationItem);
            });

            codeNavigation = tippy(document.querySelector(".blob-wrapper"), {
              content: symbolNavigation,
              interactive: true,
              arrow: false,
              animation: false,
              duration: 0,
              placement: "right-start",
              offset: [0, -20],
              theme: "light-border",
              trigger: "manual",
              hideOnClick: false
            });
            codeNavigation.show();
          }
        })();
        break;
      case "hover":
        (() => {
          const element = document.querySelector(
            `.symbol-${event.message.line}-${event.message.character}`
          );

          const value = event.message.value;
          if (value) {
            if (!popoverContent) {
              popoverContent = document.createElement("div");
            }

            element.dataset.hoverContent = value;
            popoverContent.innerHTML = `${marked(value)}`;
            hoverTooltip = tippy(element, {
              content: popoverContent,
              maxWidth: 800,
              theme: "light-border"
            });
            if (value) {
              hoverTooltip.show();
            }
          }
        })();
        break;
      case "definition":
        (() => {
          const element = document.querySelector(
            `.symbol-${event.message.line}-${event.message.character}`
          );

          const value = event.message.value;
          if (value && value.uri) {
            const href = `${parsedUrl.protocol}://${parsedUrl.resource}/${parsedUrl.full_name}/${parsedUrl.filepathtype}/${parsedUrl.ref}/${value.uri}`;
            element.classList.add("-sourcekit-for-safari_link");
            element.onclick = () => {
              console.log(href);
              document.location.href = href;
            };
          }
        })();
        break;
      default:
        break;
    }
  });
};

let href = normalizedLocation();
window.onload = () => {
  let body = document.querySelector("body"),
    observer = new MutationObserver(mutations => {
      mutations.forEach(mutation => {
        const newLocation = normalizedLocation();
        if (href != newLocation) {
          href = newLocation;
          setTimeout(() => {
            activate();
          }, 1000);
        }
      });
    });

  const config = {
    childList: true,
    subtree: true
  };

  observer.observe(body, config);
};

document.addEventListener("DOMContentLoaded", event => {
  activate();
});
