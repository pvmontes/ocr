#Use of Tesseract for R: https://cran.r-project.org/web/packages/tesseract/vignettes/intro.html

library(tesseract)
library(magick)


# tesseract_download(lang, datapath = NULL, progress = interactive())


eng <- tesseract("eng")
text <- tesseract::ocr("http://jeroen.github.io/images/testocr.png", engine = eng)
cat(text)


#The ocr_data() function returns all words in the image along with a bounding box and confidence rate.
results <- tesseract::ocr_data("http://jeroen.github.io/images/testocr.png", engine = eng)
results


#To list the languages that we currently have installed.
tesseract_info()


#By default the R package only includes English training data. Windows and Mac users 
#can install additional training data using  
tesseract_download("spa")   #To load the Spanish language.

#Now we have to load the dictionary.
(spanish_dictionary <- tesseract("spa"))


#Example of text image from an English book. After I can test with a Statistics Spanish book.
input <- image_read("https://jeroen.github.io/images/bowers.jpg")


text <- input %>%
  image_resize("2000x") %>%
  image_convert(type = 'Grayscale') %>%
  image_trim(fuzz = 40) %>%
  image_write(format = 'png', density = '300x300') %>%
  tesseract::ocr() 

cat(text)




# input_ticket <- image_read(filenames[1])    #It works.

input_ticket6 <- image_read("ticket6.jpg")

text_ticket6 <- input_ticket6 %>%
                image_resize("2000x") %>%
                image_modulate(brightness = 120) %>%
                image_convert(type = 'Grayscale') %>%
                image_trim(fuzz = 40) %>%
                image_write(format = 'png', density = '300x300') %>%
                # image_enhance() %>%   #===================
                # image_median() %>%
                # image_contrast() %>%
                tesseract::ocr() 


cat(text_ticket6)

str(text_ticket)





  #Increase brightness
  magick::image_reducenoise() %>%
  
