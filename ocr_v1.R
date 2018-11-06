# https://ropensci.org/blog/2018/08/28/birds-ocr/


install.packages("magrittr")
library(magrittr)

install.packages("taxize")
library(taxize)

install.packages("magick") #magick enhances quality of images.
library(magick)

install.packages("tesseract")
library(tesseract)

tesseract_info() #We obtain which languages are loaded in tesseract.
(spanish_dictionary <- tesseract("spa"))  #We load the Spanish dictionary.

install.packages("cld2")  
library(cld2)  #Google's compact language detector 2

install.packages("cld3")
library(cld3) #Google's compact language detector 3



#We load the content of folder; (in this case the current folder).
filenames <- fs::dir_ls(".")


#We read the ticket saved like image in the folder.
magick::image_read(filenames[1])

#We are going to prepare the image.
crop_ticket <- function(filename) {
  image <- magick::image_read(filename)
  height <- magick::image_info(image)$height
  
  #Crop the top of the image 
   image <- magick::image_crop(image,paste0("+0+",round(0.01*height))) %>%  #I don't need to crop the image.
          #Convert the image to black and white
          magick::image_convert(type = "grayscale")  %>%
          #Increase brightness
           magick::image_modulate(brightness = 120) %>%
           magick::image_reducenoise() %>%
           magick::image_enhance() %>%
           magick::image_median() %>%
           magick::image_contrast()
  
  #We'll need the filename later.
  attr(image, "filename") <- filename
  return(image)
}

crop_ticket(filenames[1]) #We can see the enhanced image.


#Proccess OCR itself.
get_names <- function(image) {
  filename <- attr(image, "filename")
  ocr_options <- list(tessedit_pageseg_mode = 1)
  
  text <- magick::image_ocr(image, options = ocr_options)
  text <- stringr::str_split(text, "\n", simplify = TRUE)
  # text <- stringr::str_remove_all(text, "[0-9]")   #It removes the numbers.
  # text <- stringr::str_remove_all(text, "[:punct:]")   #It removes punctuation marks, ¿también tildes?
  text <- trimws(text)  #It removes white spaces.
  text <- stringr::str_remove_all(text, "~") 
  text <- text[text != ""]
  text <- tolower(text) #It makes the letters in lowercase.
  
  # It removes one letter words.
  # https://stackoverflow.com/questions/31203843/r-find-and-remove-all-one-to-two-letter-words   <- Puede que esto no nos interese.
  # text <- stringr::str_remove_all(text, " *\\b[[:alpha:]]{1,2}\\b *")
  text <- text[text != ""]
  
  
  # keep only the words that are recognized as either Latin
  # or English by cld2 or cld3
  if(length(text) > 0){
    results <- tibble::tibble(text = text,
                              cld2 = cld2::detect_language(text),
                              cld3 = cld3::detect_language(text),
                              filename = filename)
    
    results[results $cld2 %in% c("la", "es", "en") |
              results$cld3 %in% c("la", "es", "en"),]
  }else{
    return(NULL)
  }
}


(results1 <- filenames[1] %>%
    magick::image_read() %>%
    get_names())     #Error



(results2 <- filenames[1] %>%
    crop_ticket() %>%
    get_names())  #We obtain some errors but some results.





ticket_names <- purrr::map(filenames[1], crop_ticket) %>%
                purrr::map_df(get_names)




safe_resolve <- function(text){
  
              results <- taxize::gnr_resolve(text, best_match_only = TRUE)
  
              if(nrow(results) == 0){
                      list(NULL)
              }else{
                      list(results)
              }
}




ticket_names <- dplyr::group_by(ticket_names, text) %>%
                dplyr::mutate(gnr = ifelse(cld2 == "la" | cld3 == "la", safe_resolve(text),list(NULL)))

str(ticket_names)

