import React, { useState, useRef, useEffect } from 'react';
import styles from '../styles/components/Dropdown.module.css'

interface DropdownProps {
    value: number;
    options: String[];
    onChange: (event: number) => void;
}

export default function Dropdown({ value, options, onChange }: DropdownProps) {
    const [isSelected, setIsSelected] = useState(false)

    const handleDropdown = () => {
        if (isSelected) {
            setIsSelected(false)
        }
        else {
            setIsSelected(true)
        }
    }

    const selectRef = useRef(null)

    const checkIfClickedOutside = (event) => {
        if(
            isSelected && 
            selectRef.current && 
            !selectRef.current.contains(event.target)
        ) {
            setIsSelected(false)
        }
    }

    useEffect(() => {
        document.addEventListener("click", checkIfClickedOutside, true)
        return () => {
            document.removeEventListener("click", checkIfClickedOutside, true)
        }
    })

    const onOptionClicked = (value) => {
        onChange(value)
        setIsSelected(false)
    }

    const displayRole = options[value]

    return(
        <div 
            className={styles.group}
            ref={selectRef}
        >
            <button 
                onClick={handleDropdown}
                className={styles.button_normal}
            >
                <p>{displayRole}</p>
            </button>
            {isSelected ? (
                <div className={styles.dropdown}>
                    <button
                        className={styles.button}
                        onClick={() => onOptionClicked(0)}
                        key={1}>
                        <p>Member</p>
                    </button>
                    <button
                        className={styles.button}
                        onClick={() => onOptionClicked(1)}
                        key={2}>
                        <p>Admin</p>
                    </button>
                    <button
                        className={styles.button}
                        onClick={() => onOptionClicked(2)}
                        key={3}>
                        <p>Owner</p>
                    </button>
                </div>
            ) :
                undefined
            }
        </div>
    )
}