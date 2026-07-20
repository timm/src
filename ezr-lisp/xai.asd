(defsystem "xai"
  :author "Tim Menzies <timm@ieee.org>"
  :license "MIT"
  :homepage "https://github.com/timm/src"
  :version "0.1"
  :description
  "Landscape analysis for XAI and optimization CSVs."
  :components ((:file "xai"))
  :in-order-to ((test-op (test-op "xai/eg"))))

(defsystem "xai/eg"
  :description "Unit tests and studies for xai."
  :depends-on ("xai")
  :components ((:file "xai-eg")))

(defsystem "xai/dtlz"
  :description "DTLZ1-7 live-model driver for xai."
  :depends-on ("xai")
  :components ((:file "dtlz")))
