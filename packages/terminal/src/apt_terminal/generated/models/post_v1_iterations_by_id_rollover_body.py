from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1IterationsByIdRolloverBody")


@_attrs_define
class PostV1IterationsByIdRolloverBody:
    """
    Attributes:
        to_iteration_id (None | str): where the unfinished cards go. An iteration in the SAME workspace (never this
            one), or null to send them back to the backlog — which is the honest destination when the next cycle does not
            exist yet.
    """

    to_iteration_id: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        to_iteration_id: None | str
        to_iteration_id = self.to_iteration_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "to_iteration_id": to_iteration_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)

        def _parse_to_iteration_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        to_iteration_id = _parse_to_iteration_id(d.pop("to_iteration_id"))

        post_v1_iterations_by_id_rollover_body = cls(
            to_iteration_id=to_iteration_id,
        )

        post_v1_iterations_by_id_rollover_body.additional_properties = d
        return post_v1_iterations_by_id_rollover_body

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
