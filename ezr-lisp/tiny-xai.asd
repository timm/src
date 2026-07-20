(defsystem "tiny-xai"
  :author "Tim Menzies <timm@ieee.org>"
  :license "MIT"
  :homepage "https://github.com/timm/src"
  :version "0.1"
  :description
  "Landscape analysis for XAI and optimization CSVs."
  :components ((:file "tiny-xai"))
  :in-order-to ((test-op (test-op "tiny-xai/eg"))))

(defsystem "tiny-xai/eg"
  :description "Unit tests and studies for tiny-xai."
  :depends-on ("tiny-xai")
  :components ((:file "tiny-xai-eg")))

(defsystem "tiny-xai/dtlz"
  :description "DTLZ1-7 live-model driver for tiny-xai."
  :depends-on ("tiny-xai")
  :components ((:file "dtlz")))
