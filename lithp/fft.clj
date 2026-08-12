;; fft.clj -- fft.lisp said in Clojure, function for
;; function. Fast-and-frugal trees over a csv table.
;; Immutable where the lisp mutates: adds fold, grows
;; returns [bias tree] pairs. (c) 2026 Tim Menzies,
;; MIT license.
(require '[clojure.string :as str])

(def my (atom {:seed 1234567891 :p 2 :bins 7 :depth 4
               :file "$MOOT/optimize/misc/auto93.csv"}))
(def big 1e32)

;;; 1. columns ------------------------------------------
(defn num [] {:n 0 :mu 0.0 :m2 0.0})

(defn sym [] {})

(defn sd [{:keys [n m2]}]
  (if (< n 2) 0 (Math/sqrt (/ (max 0.0 m2) (dec n)))))

(defn welford [{:keys [n mu m2]} v]
  (let [n (inc n) d (- v mu) mu (+ mu (/ d n))]
    {:n n :mu mu :m2 (+ m2 (* d (- v mu)))}))

(defn norm [i v]
  (let [z (/ (- v (:mu i)) (+ (sd i) 1e-32))]
    (/ 1 (+ 1 (Math/exp (* -1.7 (max -3.0 (min 3.0 z))))))))

(defn mix [i j]
  (if (:mu i)
    (let [m (+ (:n i) (:n j)) d (- (:mu j) (:mu i))]
      (if (< m 1) (num)
        {:n m
         :mu (/ (+ (* (:n i) (:mu i)) (* (:n j) (:mu j))) m)
         :m2 (+ (:m2 i) (:m2 j)
                (/ (* d d (:n i) (:n j)) m))}))
    (merge-with + i j)))

;;; 2. data ---------------------------------------------
(defn add [i v]
  (cond (= v "?") i
        (:mu i)   (welford i v)
        :else     (update i v (fnil inc 0))))

(defn adds
  ([lst] (adds lst (num)))
  ([lst it] (reduce add it lst)))

(defn role [i s at]
  (let [z (last s)
        i (assoc-in i [:cols at]
            (if (Character/isLowerCase (first s))
              (sym) (num)))]
    (cond (#{\- \+ \!} z)
            (-> i (assoc-in [:goal at] (if (= z \+) 1 0))
                  (update :y conj at))
          (not= z \X) (update i :x conj at)
          :else i)))

(defn data [[names & rows]]
  (reduce
    (fn [i row]
      (update i :cols
        #(reduce-kv (fn [m at c] (update m at add (row at)))
                    % %)))
    (reduce #(role %1 (names %2) %2)
            {:names names :x [] :y [] :goal {} :cols {}
             :rows rows}
            (range (count names)))
    rows))

;;; 3. discretization -----------------------------------
(defn bin [c v]
  (if (:mu c)
    (int (Math/floor (* (:bins @my) (norm c v)))) v))

(defn cuts-of [c bins hi at]
  (if (:mu c)
    (rest (reductions
            (fn [[_ _ _ l] k]
              [at (- big) (hi k) (mix l (bins k))])
            [0 0 0 (num)]
            (butlast (sort (keys bins)))))
    (map (fn [k] [at (hi k) (hi k) (bins k)]) (keys bins))))

(defn cuts-at [c lst ys at]
  (let [[bins hi]
        (reduce
          (fn [[bins hi] [r y1]]
            (let [v (r at)]
              (if (= v "?") [bins hi]
                (let [k (bin c v)]
                  [(update bins k #(add (or % (num)) y1))
                   (update hi k
                     #(if (:mu c) (max (or % (- big)) v)
                          v))]))))
          [{} {}] (map vector lst ys))]
    (cuts-of c bins hi at)))

(defn cuts [i lst y]
  (let [ys (map y lst)]
    (mapcat #(cuts-at ((:cols i) %) lst ys %) (:x i))))

;;; 4. grow trees ---------------------------------------
(defn mink [lst]
  (let [p (:p @my)]
    (Math/pow (/ (reduce + (map #(Math/pow (abs %) p) lst))
                 (count lst))
              (/ 1.0 p))))

(defn disty [i row]
  (mink (map #(- (norm ((:cols i) %) (row %))
                 ((:goal i) %))
             (:y i))))

(defn has [v lo hi]
  (cond (= v "?")   true
        (string? v) (= v lo)
        :else       (<= lo v hi)))

(defn least [l f]
  (reduce #(if (<= (f %1) (f %2)) %1 %2) l))

(defn most [l f]
  (reduce #(if (>= (f %1) (f %2)) %1 %2) l))

(defn splits [i y root]
  (let [enough (Math/pow (count (:rows root)) 0.33)
        cs (remove #(<= (:n (nth % 3)) enough)
                   (cuts i (:rows i) y))]
    (when (seq cs)
      (for [[bit pick] [[0 least] [1 most]]
            :let [[at lo hi leaf] (pick cs #(:mu (nth % 3)))
                  no (remove #(has (% at) lo hi) (:rows i))]
            :when (seq no)]
        [bit {:at at :lo lo :hi hi :left leaf} no]))))

(defn grows
  ([i y root] (grows i y root 0))
  ([i y root d]
   (or (when (< d (:depth @my))
         (seq (for [[bit nd no] (splits i y root)
                    :let [kid (data (cons (:names i) no))]
                    [bias r] (grows kid y root (inc d))]
                [(str bit bias) (assoc nd :right r)])))
       [["" (adds (map y (:rows i)))]])))

;;; 5. use trees ----------------------------------------
(defn predict [tr row]
  (if (:at tr)
    (recur (if (has (row (:at tr)) (:lo tr) (:hi tr))
             (:left tr) (:right tr))
           row)
    (:mu tr)))

(defn err [tr lst y]
  (/ (reduce + (map #(abs (- (y %) (predict tr %))) lst))
     (count lst)))

(defn tune [cands lst y] (least cands #(err % lst y)))

(defn rule [i {:keys [at lo hi]}]
  (let [s ((:names i) at)]
    (cond (= lo hi)      (str s " == " lo)
          (= lo (- big)) (str s " <= " hi)
          :else          (str s " >= " lo))))

(defn show [i tr]
  (if (:at tr)
    (let [l (:left tr)]
      (printf "if %-30s then d2h %.2f n=%d%n"
              (rule i tr) (double (:mu l)) (:n l))
      (show i (:right tr)))
    (printf "%-33s leaf  d2h %.2f n=%d%n"
            "" (double (:mu tr)) (:n tr))))

;;; 6. strings, csv, cli, rand --------------------------
(defn thing [s]
  (let [s (str/trim s)]
    (or (parse-long s) (parse-double s)
        ({"True" true "False" false} s s))))

(defn path [s]
  (if (str/starts-with? s "$MOOT")
    (str (or (System/getenv "MOOT")
             (str (System/getProperty "user.home")
                  "/gits/moot"))
         (subs s 5))
    s))

(defn csv [file]
  (for [l (str/split-lines (slurp (path file)))
        :let [l (str/trim l)]
        :when (and (seq l) (not= (first l) \#))]
    (mapv thing (str/split l #","))))

(defn cli [args]
  (doseq [[f v] (partition 2 1 args), k (keys @my)]
    (when (= f (str "-" (first (name k))))
      (swap! my assoc k (thing v)))))

(def seed* (atom 1234567891))

(defn rint [n]
  (int (* n (/ (swap! seed*
                      #(mod (* 16807 %) 2147483647))
               2147483647.0))))

(defn few [l n]
  (loop [v (vec l) i (dec (count v))]
    (if (< i 1) (take n v)
      (let [j (rint (inc i))]
        (recur (assoc v i (v j) j (v i)) (dec i))))))

;;; 7. demos, start -------------------------------------
(defn eg-main []
  (let [i (data (csv (:file @my)))
        y #(disty i %)]
    (show i (tune (map second (grows i y i))
                  (:rows i) y))))

(defn eg-trees []
  (let [i (data (csv (:file @my)))
        y #(disty i %)]
    (doseq [[k [bias tr]]
            (map-indexed vector (grows i y i))]
      (printf
        "===== tree %2d   bias %-5s   err %.3f =====%n"
        (inc k) bias (double (err tr (:rows i) y)))
      (show i tr) (println))))

(defn eg-grows [reps k]
  (let [all (csv (:file @my))
        t0  (System/nanoTime)
        m   (last (doall
                    (for [_ (range reps)]
                      (let [i (data (cons (first all)
                                          (few (rest all) k)))]
                        (count (grows i #(disty i %) i))))))
        s   (/ (- (System/nanoTime) t0) 1e9)]
    (printf "%dx (sample %d, %d trees): %.3f s -> %.1f ms%n"
            reps k m s (* 1000 (/ s reps)))))

(cli *command-line-args*)
(reset! seed* (:seed @my))
(cond (some #{"--grows"} *command-line-args*) (eg-grows 10 100)
      (some #{"--trees"} *command-line-args*) (eg-trees)
      :else (eg-main))
