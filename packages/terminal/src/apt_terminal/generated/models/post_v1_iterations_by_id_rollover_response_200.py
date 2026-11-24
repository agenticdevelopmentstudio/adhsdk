from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IterationsByIdRolloverResponse200")


@_attrs_define
class PostV1IterationsByIdRolloverResponse200:
    """
    Attributes:
        moved (int): how many unfinished cards were moved
        to_iteration_id (None | str): where they went; null = the backlog
        object_ (Literal['iteration'] | Unset):
    """

    moved: int
    to_iteration_id: None | str
    object_: Literal["iteration"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        moved = self.moved

        to_iteration_id: None | str
        to_iteration_id = self.to_iteration_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "moved": moved,
                "to_iteration_id": to_iteration_id,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        moved = d.pop("moved")

        def _parse_to_iteration_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        to_iteration_id = _parse_to_iteration_id(d.pop("to_iteration_id"))

        object_ = cast(Literal["iteration"] | Unset, d.pop("object", UNSET))
        if object_ != "iteration" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'iteration', got '{object_}'")

        post_v1_iterations_by_id_rollover_response_200 = cls(
            moved=moved,
            to_iteration_id=to_iteration_id,
            object_=object_,
        )

        post_v1_iterations_by_id_rollover_response_200.additional_properties = d
        return post_v1_iterations_by_id_rollover_response_200

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
