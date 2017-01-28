require 'csv'

class UPeCImport

  USER_ID = 1
  COLORS = [
    'BF1E2E', 
    'F1592A', 
    'F7941D', 
    '9EB83B', 
    '3AB54A', 
    '12A89D', 
    '25AAE2', 
    '0E76BD', 
    '652D90', 
    '92278F', 
    'ED207B', 
    '8C6238'
  ]

  def initialize(filename={})
    raw = CSV.read(filename)
    process_all raw
  end

  def self.delete_db 
    # Clean all DDBB
    Topic.delete_all
    Post.delete_all
    Category.delete_all
  end

  def get_category_color category_name
    case category_name
    when "Un nou model econòmic i ecològic"
      "9EB83B"
    when "Un nou model de benestar"
      "F7941D"
    when "Un país fratern i sobirà"
      "ED207B"
    when "Una revolució democràtica i feminista"
      "652D90"
    when "Un país inclusiu"
      "0E76BD"
    when "Un projecte de país des de tots els territoris"
      "12A89D"
    when "Suport"
      "666666"
    when "Forum Obert"
      "000000"
    else
      debugger
    end
  end

  def get_category_name(category_name)
    case category_name
    when "Títol: 1. Un nou model econòmic i ecològic basat en el bé comú"
      "Un nou model econòmic i ecològic"
    when "Títol: 2. Un nou model de benestar per una societat justa i igualitària"
      "Un nou model de benestar"
    when "Títol: 3. Un país fratern i sobirà en tots els àmbits"
      "Un país fratern i sobirà"
    when "Títol: 4. Una revolució democràtica i feminista"
      "Una revolució democràtica i feminista"
    when "Títol: 5. Un país inclusiu on tothom tingui cabuda"
      "Un país inclusiu"
    when "Títol: 6. Un projecte de país des de tots els territoris"
      "Un projecte de país des de tots els territoris"
    else
      debugger
    end
  end

  def delete_last_post_and_topic
    # Deletes the last Post and Topic
    # By default Discourse creates an "About the..." pinned Post/Topic
    Topic.last.delete
    Post.last.delete
  end

  def create_category category_name
    # Create category given a name
    category = Category.find_or_create_by(
      name: category_name,
      color: get_category_color(category_name),
      user_id: USER_ID
    )
    delete_last_post_and_topic
    category
  end

  def create_subcategory subcategory_name, category
    # Create subcategory given a name and a category object
    subcategory = Category.find_or_create_by(
      name: subcategory_name, 
      parent_category: category, 
      color: COLORS.pop,
      user_id: USER_ID
    )
    delete_last_post_and_topic
    subcategory
  end

  def create_topic topic_title, topic_body, category
    # Create a Topic and a first Post (required by Discourse)
    topic = Topic.create(
      title: topic_title, 
      category: category, 
      user_id: USER_ID
    )
    debugger unless topic.valid?
    # Doesn't like titles like "Diagnosi", too little chars :/ 
    post = Post.create(
      raw: topic_body, 
      user_id: USER_ID, 
      topic: topic
    ) 
    debugger unless post.valid?
    topic
  end

  def create_master_topic topics, topic_body
    topic_body = topic_body
    topic_body << "\n\n En aquesta categoria encontraras aquestes aportacions inicials: \n\n" 
    topics.each do |t|
      if t.title.starts_with? "Diagnosi" 
        topic_body << "</ul><h2>#{t.category.name}</h2>"
        topic_body << "<ul><li><a href=#{t.url}>#{t.title}</a></li>"
      else
        topic_body << "<li><a href=#{t.url}>#{t.title}</a></li>"
      end
    end
    topic_body << "</ul>"
    # Create a Topic and a first Post (required by Discourse)
    topic = Topic.create(
      title: "Introducció de #{topics.first.category.parent_category.name}",
      category: topics.first.category.parent_category,
      user_id: USER_ID,
      pinned_at: DateTime.now
    )
    debugger unless topic.valid?
    # Doesn't like titles like "Diagnosi", too little chars :/ 
    post = Post.create(
      raw: topic_body,
      user_id: USER_ID, 
      topic: topic
    ) 
    debugger unless post.valid?
    topic
  end

  def process_all raw
    # Creates Suport and Forum Obert forums
    create_category "Suport"
    category_forum = create_category "Forum Obert"

    # Create category from first row first line
    category_name = get_category_name raw[0][0]
    puts "Creating Category \t" + category_name
    category = create_category category_name

    # Creates Topic to debate on Forum Obert
    topic_body = "Discuteix! \n\n Lorem Ipsum es simplemente el texto de relleno de las imprentas y archivos de texto. Lorem Ipsum ha sido el texto de relleno estándar de las industrias desde el año 1500, cuando un impresor (N. del T. persona que se dedica a la imprenta) desconocido usó una galería de textos y los mezcló de tal manera que logró hacer un libro de textos especimen. No sólo sobrevivió 500 años, sino que tambien ingresó como texto de relleno en documentos electrónicos, quedando esencialmente igual al original. Fue popularizado en los 60s con la creación de las hojas 'Letraset', las cuales contenian pasajes de Lorem Ipsum, y más recientemente con software de autoedición, como por ejemplo Aldus PageMaker, el cual incluye versiones de Lorem Ipsum."
    create_topic "Debat obert de #{category_name}", topic_body, category_forum

    # For later, a list of all topics to making the Master/Pinned Topic for this Category
    topics = []

    (1..100).each do |column|
      # Create or find this subcategory by name
      subcategory_name = raw[2][column]
      unless subcategory_name.nil?
        puts "Creating Subcategory \t" + subcategory_name
        subcategory = create_subcategory subcategory_name, category
        (3..100).each do |line|
          # line = 3
          # Create topics on subcategory 
          unless raw[line].nil? or raw[line][column].nil?
            topic_title = raw[line][column].split("\n")[0]
            topic_body = raw[line][column].split("\n")[1..-1].join("\n\n")
            topic_title = topic_title.starts_with?("Diagnosi") ? "Diagnosi de #{subcategory.name}" : topic_title
            puts "Creating Topic \t\t" + topic_title
            topics << create_topic(topic_title, topic_body, subcategory)
          end
        end
      end
    end
    
    # Create the Introductory for Subcategory Master Topic, with Intro text and Initial Topics
    master_topic_body = raw[3][0]
    create_master_topic(topics, master_topic_body)
  end

end
