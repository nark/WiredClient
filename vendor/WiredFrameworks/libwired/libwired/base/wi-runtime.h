/* $Id$ */

/*
 *  Copyright (c) 2005-2009 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */



/**
 * @file wi-runtime.h 
 * @brief This file provide an abstract object-oriented runtime for C environment.
 * @author Axel Andersson, Rafaël Warnault
 * @version 2.0
 *
 * The Wired runtime provides an object layer to manage wired data in an object-oriented way, 
 * supporting dynamic memory allocation and management based on reference counting system. 
 * It is very similar to the Objective-C runtime, also based on C language.
 * General design and features use a corresponding vocabulary.
 *
 */

#ifndef WI_RUNTIME_H
#define WI_RUNTIME_H

#include <wired/wi-base.h>




/**
 * @typedef wi_runtime_instance_t
 *
 * Raw type used by runtime to define an instance of a class
 */
typedef void							wi_runtime_instance_t;



/**
 * @typedef wi_runtime_id_t
 *
 * Runtime ID
 */
enum {
    /** Null ID for the runtime */
	WI_RUNTIME_ID_NULL					= 0
};
typedef uint16_t						wi_runtime_id_t;





/**
 * @enum Runtime options
 * @brief Low-level options for runtime instances
 */
enum {
    /** Zombie reference option */
	WI_RUNTIME_OPTION_ZOMBIE			= (1 << 0),
    
    /** Immutable reference option */
	WI_RUNTIME_OPTION_IMMUTABLE			= (1 << 1),
    
    /** Mutable reference option */
	WI_RUNTIME_OPTION_MUTABLE			= (1 << 2)
};





typedef void							wi_dealloc_func_t(wi_runtime_instance_t *);
typedef wi_runtime_instance_t *			wi_copy_func_t(wi_runtime_instance_t *);
typedef wi_boolean_t					wi_is_equal_func_t(wi_runtime_instance_t *, wi_runtime_instance_t *);
typedef wi_string_t *					wi_description_func_t(wi_runtime_instance_t *);
typedef wi_hash_code_t					wi_hash_func_t(wi_runtime_instance_t *);
typedef wi_runtime_instance_t *			wi_retain_func_t(wi_runtime_instance_t *);
typedef void							wi_release_func_t(wi_runtime_instance_t *);
typedef wi_integer_t					wi_compare_func_t(wi_runtime_instance_t *, wi_runtime_instance_t *);

/**
 * @brief Runtime Instance Class 
 * @extends wi_runtime_base_t
 *
 * wi_runtime_class_t represents a Wired class instance 
 * used by the Wired runtime to manage object adstraction.
 * Each class instance contains a name and function pointers
 * for basis memory and runtime features.
 */
struct _wi_runtime_class {
	const char							*name;          /** The class name */
	wi_dealloc_func_t					*dealloc;       /** Function pointer to function responsible of object deallocation */
	wi_copy_func_t						*copy;          /** Function pointer to function responsible of object copy */
	wi_is_equal_func_t					*is_equal;      /** Function pointer to function responsible of object comparison */
	wi_description_func_t				*description;   /** Function pointer to function responsible of object description */
	wi_hash_func_t						*hash;          /** Function pointer to function responsible of object hash */
};
typedef struct _wi_runtime_class		wi_runtime_class_t;





/**
 * @brief Runtime Base Class 
 * 
 * wi_runtime_base_t represents the top-level superclass
 * in the libwired object graph. It provides attributes
 * which glue an object instance to the Wired runtime and 
 * allows memory management by reference counting.
 */
struct _wi_runtime_base {
	uint32_t							magic;
	wi_runtime_id_t						id;
	uint16_t							retain_count;
	uint8_t								options;
};
typedef struct _wi_runtime_base			wi_runtime_base_t;





/*** RUNTIME CLASSES MANAGEMENT */
/**
 * @fn WI_EXPORT wi_runtime_id_t wi_runtime_register_class(wi_runtime_class_t *)
 * @brief Dynamically register a class with the runtime
 * @param wclass must be a valid wi_runtime_class or descendant
 * @return A new generated ID for the class
 * 
 * NOTE: Each class must be registered to the runtime before to be used by it.
 * Have a look to wi_initialize() function of wi-base.c file for more information.
 * 
 */
WI_EXPORT wi_runtime_id_t				wi_runtime_register_class(wi_runtime_class_t *wclass);

/**
 * @fn WI_EXPORT wi_runtime_class_t * wi_runtime_class_with_name(wi_string_t *classname)
 * @brief Create an class object for a given name
 * @param classname is the name of the target class
 * @return A new class instance
 *
 * NOTE: Class must be registered using wi_runtime_register_class before this mathod was called.
 *
 */
WI_EXPORT wi_runtime_class_t *			wi_runtime_class_with_name(wi_string_t *classname);

/**
 * @fn WI_EXPORT wi_runtime_class_t * wi_runtime_class_with_id(wi_runtime_id_t cid)
 * @brief Create an class object for a given class ID
 * @param cid is the ID of the target class
 * @return A new class instance
 *
 * NOTE: Class must be registered using wi_runtime_register_class before this mathod was called.
 *
 */
WI_EXPORT wi_runtime_class_t *			wi_runtime_class_with_id(wi_runtime_id_t cid);

/**
 * @fn WI_EXPORT wi_runtime_id_t wi_runtime_id_for_class(wi_runtime_class_t *aclass)
 * @brief Retrieve class ID for a given class
 * @param aclass must be a valid wi_runtime_class or descendant
 * @return The ID of the class against the runtime
 *
 * NOTE: Class must be registered using wi_runtime_register_class before this mathod was called.
 *
 */
WI_EXPORT wi_runtime_id_t				wi_runtime_id_for_class(wi_runtime_class_t *aclass);





/*** RUNTIME INSTANCE CONSTRUCTORS */
/**
 * @fn WI_EXPORT wi_runtime_instance_t * wi_runtime_create_instance(wi_runtime_id_t rid, size_t s)
 * @brief Create an instance with the runtime ID of a class
 * @param rid is a valid class ID
 * @param s is the target instance size
 * @return A new object instance
 */
WI_EXPORT wi_runtime_instance_t *		wi_runtime_create_instance(wi_runtime_id_t rid, size_t s);

/**
 * @fn WI_EXPORT wi_runtime_instance_t * wi_runtime_create_instance_with_options(wi_runtime_id_t rid, size_t s, uint8_t opt)
 * @brief Create an instance with the runtime ID of a class and with initialisation options
 * @param rid is a valid class ID
 * @param s is the target instance size
 * @param opt Initialization options
 * @return A new object instance
 */
WI_EXPORT wi_runtime_instance_t *		wi_runtime_create_instance_with_options(wi_runtime_id_t rid, size_t s, uint8_t opt);






/*** RUNTIME INSTANCE ACCESSORS */
/**
 * @fn WI_EXPORT wi_runtime_class_t * wi_runtime_class(wi_runtime_instance_t *instance)
 * @brief Retrieve class object for a given runtime instance
 * @param instance must be a valid wi_runtime_instance or descendant
 * @return The class matching the given instance
 *
 */
WI_EXPORT wi_runtime_class_t *			wi_runtime_class(wi_runtime_instance_t *instance);

/**
 * @fn WI_EXPORT wi_string_t * wi_runtime_class_name(wi_runtime_instance_t *instance)
 * @brief Retrieve class name for a given runtime instance
 * @param instance must be a valid wi_runtime_instance or descendant
 * @return The name of the class matching the given instance
 *
 */
WI_EXPORT wi_string_t *					wi_runtime_class_name(wi_runtime_instance_t *instance);

/**
 * @fn WI_EXPORT wi_runtime_id_t wi_runtime_id(wi_runtime_instance_t *instance)
 * @brief Retrieve runtime ID for a given runtime instance
 * @param instance must be a valid wi_runtime_instance or descendant
 * @return The ID of the given instance
 *
 */
WI_EXPORT wi_runtime_id_t				wi_runtime_id(wi_runtime_instance_t *instance);

/**
 * @fn WI_EXPORT uint8_t wi_runtime_options(wi_runtime_instance_t *instance)
 * @brief Retrieve initialization options for a given runtime instance
 * @param instance must be a valid wi_runtime_instance or descendant
 * @return Initialization options of the given instance
 *
 */
WI_EXPORT uint8_t						wi_runtime_options(wi_runtime_instance_t *instance);






/*** RUNTIME INSTANCE MEMORY MANAGEMENT */
/**
 * @fn WI_EXPORT wi_runtime_instance_t * wi_retain(wi_runtime_instance_t *instance)
 * @brief Increments the receiver’s reference count
 * @param instance must be a valid wi_runtime_instance or descendant
 * @return Your retained instance
 *
 * NOTE: You send an object a retain message when you want to prevent it from being 
 * deallocated until you have finished using it.
 */
WI_EXPORT wi_runtime_instance_t * 		wi_retain(wi_runtime_instance_t *instance);

/**
 * @fn WI_EXPORT uint16_t wi_retain_count(wi_runtime_instance_t *instance)
 * @brief Return the number of counted reference for a given instance
 * @param instance must be a valid wi_runtime_instance or descendant
 * @return Number of counted reference for a given instance
 *
 */
WI_EXPORT uint16_t						wi_retain_count(wi_runtime_instance_t *instance);

/**
 * @fn WI_EXPORT void wi_release(wi_runtime_instance_t *instance)
 * @brief Decrements the receiver’s reference count
 * @param instance must be a valid wi_runtime_instance or descendant
 *
 * NOTE: The receiver is sent a dealloc message when its reference retain_count reaches 0.
 * Be aware that using this method on a non-retained instance will raise an assertion.
 */
WI_EXPORT void							wi_release(wi_runtime_instance_t *instance);





/*** RUNTIME INSTANCE HELPERS */
/**
 * @fn WI_EXPORT wi_runtime_instance_t * wi_copy(wi_runtime_instance_t *instance)
 * @brief Create a copy of the give instance
 * @param instance must be a valid wi_runtime_instance or descendant
 * @return A copy of the give instance
 *
 * NOTE: The returned instance is retained and must be released by the receiver.
 */
WI_EXPORT wi_runtime_instance_t *		wi_copy(wi_runtime_instance_t *instance);

/**
 * @fn WI_EXPORT wi_runtime_instance_t * wi_mutable_copy(wi_runtime_instance_t *instance)
 * @brief Create a mutable copy of the give instance
 * @param instance must be a valid wi_runtime_instance or descendant
 * @return A mutable copy of the give instance
 *
 * NOTE: The returned instance is retained and must be released by the receiver.
 */
WI_EXPORT wi_runtime_instance_t *		wi_mutable_copy(wi_runtime_instance_t *instance);

/**
 * @fn WI_EXPORT wi_boolean_t wi_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2)
 * @brief Check if given instances are identical
 * @param instance1 must be a valid wi_runtime_instance or descendant
 * @param instance2 must be a valid wi_runtime_instance or descendant
 * @return A boolean value indicating if given instances are identical or not
 *
 */
WI_EXPORT wi_boolean_t					wi_is_equal(wi_runtime_instance_t *instance1, wi_runtime_instance_t *instance2);

/**
 * @fn WI_EXPORT wi_string_t * wi_description(wi_runtime_instance_t *instance)
 * @brief Return the runtime description of the given instance
 * @param instance must be a valid wi_runtime_instance or descendant
 * @return An instance description as a string
 *
 */
WI_EXPORT wi_string_t *					wi_description(wi_runtime_instance_t *instance);

/**
 * @fn WI_EXPORT wi_hash_code_t wi_hash(wi_runtime_instance_t *instance)
 * @brief Return the runtime hashcode of the given instance
 * @param instance must be a valid wi_runtime_instance or descendant
 * @return The instance hashcode value against the runtime
 *
 */
WI_EXPORT wi_hash_code_t				wi_hash(wi_runtime_instance_t *instance);

/**
 * @fn WI_EXPORT void wi_show(wi_runtime_instance_t *)
 * @brief Print the instance into the log
 * @param instance must be a valid wi_runtime_instance or descendant
 *
 */
WI_EXPORT void							wi_show(wi_runtime_instance_t *);



/**
 * Zombie flag
 * 
 * A boolean value that indicates if zombie tracking is enabled.
 */
WI_EXPORT wi_boolean_t					wi_zombie_enabled;



#endif /* WI_RUNTIME_H */
