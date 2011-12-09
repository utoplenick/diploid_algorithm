require "rubygems"
require "gnuplot"

class Species
  attr_accessor :score, :genome, :code, :potency, :del_potency, :res

  def initialize ()
    #@@gen_items = ["r", "d", "R", "D"]
    @potency = 0.0
    @del_potency= 0.0
    @code = Array.new(@@length) { "x" }
    @genome= [Array.new(@@length) { @@gen_items[rand(4)] }, Array.new(@@length) { @@gen_items[rand(4)] }]
    self.calc_score
  end

  def self.gen_items
    return @@gen_items
  end

  def self.set_gen_items
    return @@gen_items=["r", "d", "R", "D"]
  end

  def self.set_var_num(num)
    @@var_num=num
  end

  def self.var_num
    return @@var_num
  end

  def self.set_length(len)
    @@length=len
  end

  def self.length
    return @@length
  end

  def ==(sp)
    @genome==sp.genome
  end

  def eql?(sp)
    #@genome==sp.genome
    self == sp
  end
  def hash
    @genome.hash
  end
  def gray_to_dec(genome_part)

    bin_genome_part = Array.new
    # calc local sum
    def calc_sum(pos, genome_part)
      s=0
      for i in 0..(pos+1)
        s+= genome_part[i].to_i
      end
      return s
    end

    genome_part="0"+genome_part
    for i in 0...(@@length/@@var_num)
      if calc_sum(i, genome_part) == 0 then
        bin_genome_part[i]=0
      elsif (calc_sum(i, genome_part) % 2) == 0 then
        bin_genome_part[i]=0
      else
        bin_genome_part[i] = 1
      end
    end

    #return bin_genome_part.to_s.to_i(2) - ("1"+"0"*(@@length/@@var_num-1)).to_i(2)
    return (bin_genome_part.to_s.to_i(2) - 512)/100.0

  end

  def lawyer()

    for i in 0...Species.length
      if genome[0][i]=="D" :
        @code[i]=1
      elsif genome[0][i]=="d" :
        @code[i]=0
      elsif (genome[1][i]== "R" || genome[1][i]=="D") :
        @code[i]=1
      else
        @code[i]=0
      end
    end
    return @code
  end


  def rastrigin_function

    def sum
      s = 0
      for i in 0...@@var_num
        s+= (@res[i]**2 - 10 * Math::cos(2*Math::PI*@res[i]))
      end
      return s
    end

    return 10*@@var_num + sum
  end

  def test_func
    def sum
      s = 0
      for i in 0...@@var_num
        s+= (@res[i]**2)
      end
      return s
    end

    return sum
  end

  def calc_score
    self.lawyer

    @res = Array.new
    i = 0
    @@var_num.times do
      @res.push((gray_to_dec(code[i..(i+=@@length / @@var_num)].to_s)).to_f)
    end

    @score = rastrigin_function
    #@score = test_func
  end

def calc_score_simple
    #self.lawyer

    @res = Array.new
    i = 0
    @@var_num.times do
      @res.push((gray_to_dec(code[i..(i+=@@length / @@var_num)].to_s)).to_f)
    end

    @score = rastrigin_function
    #@score = test_func
  end


end


########################


class Population

  attr_accessor :genomes, :number, :sum_score

  def initialize(number, genome_length, var_num)
    @number = number
    Species.set_length(genome_length)
    Species.set_var_num(var_num)
    Species.set_gen_items()
    @genomes = Array.new(number) { Species.new }
    self.calc_potency
  end

  def sort
    @genomes.each do |i|
      i.calc_score
    end

    self.genomes.sort! { |a, b| a.score <=> b.score }

  end

  def calc_potency
    self.sort
    @sum_score=0
    @genomes.each do |g|
      @sum_score+=g.score
    end

    @genomes.each do |g|

      #g.potency = (@genomes[-1].score - g.score) / (@number*@genomes[-1].score - @sum_score)
      g.potency = (1.5*@genomes[0].score+(0.5*@genomes[-1].score - g.score)) / ((1.5*@genomes[0].score+0.5*@genomes[-1].score)*@number - @sum_score)
      if g.potency == 0.0/0.0 then
        g.potency = 0.0
      end
    end

    num = @number/10
    for i in 0...num
      @genomes[i].del_potency = 0.0
    end

    part_score=0.0

    for i in num...@number
      part_score+= @genomes[i].score
    end

    for i in num...@number
      @genomes[i].del_potency = (@genomes[i].score - (1.5*@genomes[num].score-0.5*genomes[-1].score)) / (part_score -@number*(1.5*@genomes[num].score-0.5*genomes[-1].score))
    end


  end

  def crossover(parent)
    cross_pos = rand(parent[0].length-1)+1
    child=Species.new()

    for i in 0...cross_pos
      child.genome[0][i]=parent[0][i]
      child.genome[1][i]=parent[1][i]
    end

    for i in cross_pos..(Species.length-1)
      child.genome[0][i]=parent[1][i]
      child.genome[1][i]=parent[0][i]
    end

    #puts "cross_pos = " + cross_pos.to_s
    return child.genome[rand(2)]
  end

  def inversion (patient)
    a = 1
    b = rand(0)
    if (a < b) then
      return patient
    end
    inv_pos = rand(Species.length)
    return patient = patient[inv_pos..Species.length] + patient[0..(inv_pos-1)]
  end

  def mutation (patient)
    a=1

    b=rand(0)

    if (a < b) then
      return patient
    end

    mut_pos = rand(Species.length)
    not_mutated = patient[mut_pos]
    mutated = Species.gen_items[rand(4)]

    while not_mutated == mutated
      mutated = Species.gen_items[rand(4)]
    end

    patient[mut_pos] = mutated
    

    return patient
  end

  def choose_parent_genome
    p = rand(0)
    sum = 0
    @genomes.each do |g|
      sum+=g.potency
      if (sum >= p) then
        return g.genome
      end
    end
    return @genomes[0].genome
  end

  def choose_loser_index
    probability = rand(0)
    i=@number-1
    sum=0
    while i<=@number/10
      sum+=@genomes[i].del_potency
      if sum>=probability then
        return i
      end
      i-=1
    end

  return (@number-1)
  end

  def calculate
    zygote_b = self.inversion(self.mutation(self.crossover(self.choose_parent_genome)))
    zygote_a = self.inversion(self.mutation(self.crossover(self.choose_parent_genome)))
    self.genomes.delete_at(self.choose_loser_index)
    self.genomes.push(Species.new)
    self.genomes[-1].genome[0] = zygote_a
    self.genomes[-1].genome[1] = zygote_b
    self.genomes[-1].calc_score
    self.delete_duplicates
    #self.sort
    #self.calc_potency
  end

  def delete_duplicates
    self.genomes.uniq!
    (@number-self.genomes.size).times do
      self.genomes.push(Species.new)
    end
    self.calc_potency
  end

  def show
    puts "score sum = " + @sum_score.to_s
    puts "number" + @number.to_s
    self.genomes.each do |gen|
    puts gen.genome.inspect
    end
  end

end

#############################3
#
#family = Population.new(2,4,1)
#family.show
#family.genomes[0].genome = [["r", "d", "R", "D"],["r", "d", "R", "D"]]
#family.genomes[1].genome = [["r", "d", "R", "D"],["r", "d", "R", "D"]]
#family.show
#family.genomes.uniq!
#family.show

#puts (cross = (family.crossover(family.genomes[0].genome))).inspect
#puts (mut = (family.mutation(cross))).inspect
#puts (inv = (family.inversion(mut))).inspect
#puts


#puts ["r", "d", "R", "D"].inspect
#puts family.mutation(["r", "d", "R", "D"]).inspect

gena = Population.new(10, 50, 5)
gena.show
a=Array.new(3) { [] }
puts a.inspect
gena.genomes.each do |i|
  puts i.inspect
end
3000.times do |t|
  gena.calculate
  if (t%100==0) then
    a[0].push(gena.genomes[0].score)
    a[1].push(gena.sum_score/gena.number)
    a[2].push(t)
    puts t
    gena.show
    gena.genomes.each do |i|
      puts i.inspect
    end
  end
end

Gnuplot.open do |gp|
  Gnuplot::Plot.new( gp ) do |plot|

    plot.xrange "[0:1000]"
    plot.title  "Diploid yeah"
    plot.ylabel ""
    plot.xlabel "epoch_number"



    plot.data = [
      Gnuplot::DataSet.new( [a[2],a[1]] ) { |ds|
        ds.with = "linespoints"
        ds.title = "average_score"
    	  #ds.linewidth = 4
      },

      Gnuplot::DataSet.new( [a[2],a[0]] ) { |ds|
        ds.with = "linespoints"
        ds.title = "best_score"
      }
    ]

  end
end





